#!/usr/bin/env sh

echo "Now in 'cli' variant of execute-things.sh"

# execute things yay
echo "Now running finalize-image.sh"
$(which bash) /usr/local/bin/finalize-image.sh

echo "Now running entrypoint.sh"
$(which bash) /usr/local/bin/entrypoint.sh