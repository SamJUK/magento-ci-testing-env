<?php declare( strict_types = 1 );

// Applies patches.json once at build time with plain `patch`, so the image ships no
// patch plugin for the code under test to collide with.

use Composer\InstalledVersions;
use Composer\Semver\Semver;

$root = dirname( __DIR__ );
require $root . '/vendor/autoload.php';

$patches = json_decode( file_get_contents( $root . '/patches.json' ), true, 512, JSON_THROW_ON_ERROR );

foreach ( $patches['*'] as $label => $patch ) {
    foreach ( $patch['depends'] as $package => $constraint ) {
        // Replaced packages (magento/* on Mage-OS) are "installed" with no version.
        $version = InstalledVersions::isInstalled( $package ) ? InstalledVersions::getVersion( $package ) : null;
        if ( $version === null || !Semver::satisfies( $version, $constraint ) ) {
            continue 2;
        }
    }

    echo "Applying patch: $label\n";
    passthru( sprintf( 'patch -p1 --forward --batch -d %s -i %s', escapeshellarg( $root ), escapeshellarg( $root . '/' . $patch['source'] ) ), $exitCode );
    if ( $exitCode !== 0 ) {
        exit( $exitCode );
    }
}
