<?php

declare(strict_types=1);

namespace Acme\ExampleModule\Test\Integration;

class ExampleIntegrationTest extends \PHPUnit\Framework\TestCase
{
    public function testExample(): void
    {
        $objectManager = \Magento\TestFramework\Helper\Bootstrap::getObjectManager();
        $storeRepository = $objectManager->get(\Magento\Store\Api\StoreRepositoryInterface::class);
        $store = $storeRepository->get('default');
        $this->assertSame('default', $store->getCode());
    }
}