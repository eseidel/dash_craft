#!/bin/sh -e

# A script for computing combined coverage for all packages in the repo.
# This can be used for viewing coverage locally in your editor.

dart pub global activate coverage
flutter packages get
flutter test --coverage