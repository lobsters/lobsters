An authentication HTTP server that does the insane Rails
PBKDF2-then-verify-then-decrypt, which by the way is named
`decrypt_and_verify` (which makes it sound like it's doing decryption
and THEN verifcation, which makes your heart stop a little bit until
you read the source code), and then reverse-proxies the actual data we
want onto a yet-to-be-determined-but-hopefully-Haskell backend.

This data takes the form of the `session_token` stored alongside the
user's row in the `users` table.

We could do this authentication and decryption ourselves in Haskell,
but the OpenSSL bindings are poor, and there's no way to shell out to
`openssl(1)` for, at least, and at least that I could find, PBKDF2.

To test this, run `./bin/thin -R authd.ru start`. You'll need some
sort of dummy HTTP server running on port 9000 localhost, or you can
modify the source code and have it point at something else, like
requestbin.
