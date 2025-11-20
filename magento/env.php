<?php
return [
    'backend' => [
        'frontName' => getenv('MAGENTO_ADMIN_PATH') ?: 'admin'
    ],
    'remote_storage' => [
        'driver' => 'file'
    ],
    'queue' => [
        'consumers_wait_for_messages' => 1
    ],
    'crypt' => [
        'key' => getenv('MAGENTO_CRYPT_KEY') ?: bin2hex(random_bytes(16))
    ],
    'db' => [
        'table_prefix' => '',
        'connection' => [
            'default' => [
                'host' => getenv('MAGENTO_DB_HOST') ?: 'localhost',
                'dbname' => getenv('MAGENTO_DB_NAME') ?: 'magento',
                'username' => getenv('MAGENTO_DB_USER') ?: 'magento',
                'password' => getenv('MAGENTO_DB_PASSWORD') ?: 'magento',
                'model' => 'mysql4',
                'engine' => 'innodb',
                'initStatements' => 'SET NAMES utf8;',
                'active' => '1',
                'driver_options' => [
                    1014 => false
                ],
                'profiler' => 0
            ]
        ]
    ],
    'resource' => [
        'default_setup' => [
            'connection' => 'default'
        ]
    ],
    'x-frame-options' => 'SAMEORIGIN',
    'MAGE_MODE' => 'production',
    'session' => [
        'save' => 'redis',
        'redis' => [
            'host' => getenv('MAGENTO_REDIS_SESSION_HOST') ?: 'redis',
            'port' => getenv('MAGENTO_REDIS_SESSION_PORT') ?: '6379',
            'password' => getenv('MAGENTO_REDIS_SESSION_PASSWORD') ?: '',
            'database' => getenv('MAGENTO_REDIS_SESSION_DB') ?: '2',
            'timeout' => '2.5',
            'persistent_identifier' => '',
            'compression_threshold' => '2048',
            'compression_library' => 'gzip',
            'log_level' => '1',
            'max_concurrency' => '60',
            'break_after_frontend' => '5',
            'break_after_adminhtml' => '30',
            'first_lifetime' => '600',
            'bot_first_lifetime' => '60',
            'bot_lifetime' => '7200',
            'disable_locking' => '0',
            'min_lifetime' => '60',
            'max_lifetime' => '2592000',
            'sentinel_master' => '',
            'sentinel_servers' => '',
            'sentinel_connect_retries' => '5',
            'sentinel_verify_master' => '0'
        ]
    ],
    'cache' => [
        'frontend' => [
            'default' => [
                'id_prefix' => '69d_',
                'backend' => 'Magento\\Framework\\Cache\\Backend\\Redis',
                'backend_options' => [
                    'server' => getenv('MAGENTO_REDIS_CACHE_HOST') ?: 'redis',
                    'database' => getenv('MAGENTO_REDIS_CACHE_DB') ?: '0',
                    'port' => getenv('MAGENTO_REDIS_CACHE_PORT') ?: '6379',
                    'password' => getenv('MAGENTO_REDIS_CACHE_PASSWORD') ?: '',
                    'compress_data' => '1',
                    'compression_lib' => ''
                ]
            ],
            'page_cache' => [
                'id_prefix' => '69d_',
                'backend' => 'Magento\\Framework\\Cache\\Backend\\Redis',
                'backend_options' => [
                    'server' => getenv('MAGENTO_REDIS_PAGE_CACHE_HOST') ?: 'redis',
                    'database' => getenv('MAGENTO_REDIS_PAGE_CACHE_DB') ?: '1',
                    'port' => getenv('MAGENTO_REDIS_PAGE_CACHE_PORT') ?: '6379',
                    'password' => getenv('MAGENTO_REDIS_PAGE_CACHE_PASSWORD') ?: '',
                    'compress_data' => '0',
                    'compression_lib' => ''
                ]
            ]
        ],
        'allow_parallel_generation' => false,
        'graphql' => [
            'id_salt' => getenv('MAGENTO_GRAPHQL_SALT') ?: bin2hex(random_bytes(16))
        ]
    ],
    'lock' => [
        'provider' => 'db'
    ],
    'directories' => [
        'document_root_is_pub' => true
    ],
    'cache_types' => [
        'fishpig_wordpress' => 1,
        'config' => 1,
        'layout' => 1,
        'block_html' => 1,
        'collections' => 1,
        'reflection' => 1,
        'db_ddl' => 1,
        'compiled_config' => 1,
        'eav' => 1,
        'customer_notification' => 1,
        'config_integration' => 1,
        'config_integration_api' => 1,
        'full_page' => 1,
        'config_webservice' => 1,
        'translate' => 1,
        'ec_cache' => 1,
        'instagram_feed' => 1,
        'checkout' => 1
    ]
];
