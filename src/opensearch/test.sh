#!/bin/sh
# test.sh <image>: starts the image the way the Magento stacks run it (read-only root, noexec tmpfs on /tmp, no
# capabilities) and checks it has no plugins, loads JNA, and serves what Magento uses: an analysis-common analyzer,
# a painless script sort and aggregations.
set -eu
image=$1
name=opensearch-test-$$
trap 'docker rm -fv "$name" >/dev/null 2>&1 || true' EXIT

docker run -d --name "$name" --read-only --cap-drop ALL --mount type=tmpfs,dst=/tmp \
    -v /usr/share/opensearch/data \
    -e discovery.type=single-node -e DISABLE_SECURITY_PLUGIN=true \
    -e OPENSEARCH_JAVA_OPTS="-Xms64m -Xmx256m -XX:-AlwaysPreTouch" "$image" >/dev/null
q() { docker exec "$name" curl -sf -H 'Content-Type: application/json' "$@"; }
fail() { echo "FAIL: $*"; docker logs "$name" 2>&1 | tail -30; exit 1; }

i=0
until q -o /dev/null 'localhost:9200/_cluster/health?wait_for_status=green&timeout=1s'; do
    [ "$(docker inspect -f '{{.State.Running}}' "$name")" = true ] || fail "exited"
    i=$((i + 1)); [ $i -lt 180 ] || fail "not healthy after 180s"; sleep 1
done
echo "ok    healthy on a read-only root"

[ -z "$(docker exec "$name" bin/opensearch-plugin list)" ] || fail "plugins left: $(docker exec "$name" bin/opensearch-plugin list)"
echo "ok    no plugins"
! docker logs "$name" 2>&1 | grep -q 'unable to load JNA' || fail "JNA did not load"
echo "ok    JNA loaded"

q -XPUT localhost:9200/products -o /dev/null -d '{
  "settings": {"analysis": {"analyzer": {"sku": {"type": "custom", "tokenizer": "whitespace",
    "filter": ["lowercase", "asciifolding", "word_delimiter_graph"]}}}},
  "mappings": {"properties": {"name": {"type": "text", "analyzer": "sku"}, "price": {"type": "double"}}}}'
q -XPOST 'localhost:9200/products/_bulk?refresh=true' -o /dev/null --data-binary '{"index":{"_id":"7"}}
{"name":"Jupiter All-Weather Trainer","price":56.99}
{"index":{"_id":"12"}}
{"name":"Montana Wind Jacket","price":49}
{"index":{"_id":"3"}}
{"name":"Proteus Fitness Jackshirt","price":45}
'
result=$(q 'localhost:9200/products/_search?filter_path=hits.total.value,hits.hits._id,aggregations.prices.max' -d '{
  "query": {"match": {"name": "jacket ALL-WEATHER"}},
  "sort": [{"_script": {"type": "number", "order": "desc",
    "script": {"lang": "painless", "source": "Long.parseLong(doc[\"_id\"].value)"}}}],
  "aggregations": {"prices": {"stats": {"field": "price"}}}}')
expected='{"hits":{"total":{"value":2},"hits":[{"_id":"12"},{"_id":"7"}]},"aggregations":{"prices":{"max":56.99}}}'
[ "$result" = "$expected" ] || fail "search returned $result, expected $expected"
echo "ok    analyzer, painless sort and aggregation"
