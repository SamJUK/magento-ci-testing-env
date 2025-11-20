<?php declare( strict_types = 1 );

$configFile = __DIR__ . '/app/etc/config.php';
if ( !file_exists( $configFile ) ) {
    echo "Config file not found: $configFile\n";
    exit( 1 );
}

$defaultConfig = include $configFile;
if ( !is_array( $defaultConfig ) ) {
    echo "Config file does not return an array: $configFile\n";
    exit( 1 );
}

$defaultConfig = array_merge(
    $defaultConfig,
    [
        'scopes' => [
            'websites' => [
                'admin' => [
                    'website_id' => '0',
                    'code' => 'admin',
                    'name' => 'Admin',
                    'sort_order' => '0',
                    'default_group_id' => '0',
                    'is_default' => '0'
                ],
                'base' => [
                    'website_id' => '1',
                    'code' => 'base',
                    'name' => 'Main Website',
                    'sort_order' => '0',
                    'default_group_id' => '1',
                    'is_default' => '1'
                ]
            ],
            'groups' => [
                [
                    'group_id' => '0',
                    'website_id' => '0',
                    'name' => 'Default',
                    'root_category_id' => '0',
                    'default_store_id' => '0',
                    'code' => 'default'
                ],
                [
                    'group_id' => '1',
                    'website_id' => '1',
                    'name' => 'Main Website Store',
                    'root_category_id' => '2',
                    'default_store_id' => '1',
                    'code' => 'main_website_store'
                ]
            ],
            'stores' => [
                'admin' => [
                    'store_id' => '0',
                    'code' => 'admin',
                    'website_id' => '0',
                    'group_id' => '0',
                    'name' => 'Admin',
                    'sort_order' => '0',
                    'is_active' => '1'
                ],
                'default' => [
                    'store_id' => '1',
                    'code' => 'default',
                    'website_id' => '1',
                    'group_id' => '1',
                    'name' => 'Default Store View',
                    'sort_order' => '0',
                    'is_active' => '1'
                ]
            ]
        ],
        'themes' => [
            'frontend/Magento/blank' => [
                'parent_id' => null,
                'theme_path' => 'Magento/blank',
                'theme_title' => 'Magento Blank',
                'is_featured' => '0',
                'area' => 'frontend',
                'type' => '0',
                'code' => 'Magento/blank'
            ],
            'adminhtml/Magento/backend' => [
                'parent_id' => null,
                'theme_path' => 'Magento/backend',
                'theme_title' => 'Magento 2 backend',
                'is_featured' => '0',
                'area' => 'adminhtml',
                'type' => '0',
                'code' => 'Magento/backend'
            ],
            'frontend/Magento/luma' => [
                'parent_id' => 'Magento/blank',
                'theme_path' => 'Magento/luma',
                'theme_title' => 'Magento Luma',
                'is_featured' => '0',
                'area' => 'frontend',
                'type' => '0',
                'code' => 'Magento/luma'
            ]
        ],
        'system' => [
            'default' => [
                'dev' => [
                    'js' => [
                        'merge_files' => 1,
                        'minify_files' => 1,
                    ],
                    'css' => [
                        'minify_files' => 1,
                        'merge_css_files' => 1,
                    ],
                    'template' => [
                        'minify_html' => 1
                    ]
                ]
            ]
        ],
    ]
);

file_put_contents(
    $configFile,
    '<?php return ' . var_export( $defaultConfig, true ) . ';' . PHP_EOL
);