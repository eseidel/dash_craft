#!/bin/sh -e

# A script for computing combined coverage for all packages in the repo.
# This can be used for viewing coverage locally in your editor.


dart pub global activate coverage
dart pub global activate combine_coverage

# When we have flutter packages we will add a separate array for those.
DART_PACKAGES='logic'

for PACKAGE_DIR in $DART_PACKAGES
do
    echo $PACKAGE_DIR
    cd packages/$PACKAGE_DIR
    dart pub get
    dart test --coverage=coverage
    dart pub global run coverage:format_coverage --lcov --in=coverage \
        --out=coverage/lcov.info --packages=.dart_tool/package_config.json \
        --check-ignore
    cd ../..
done

# This is only needed for local viewing of coverage,
# codecov knows how to find the lcov.info files without this.
dart pub global run combine_coverage --repo-path .