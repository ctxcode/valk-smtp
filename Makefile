vc ?= valk

test:
	$(vc) build ./tests --test --run
test-mailpit:
	$(vc) build ./tests --test --run --filter "Mailpit"
lint:
	$(vc) build ./src --lint
example:
	$(vc) build ./example --run
docs:
	$(vc) doc . -o docs/api.md --markdown --no-private
	$(vc) doc . -o docs/api-full.md --markdown --no-private --full
server:
	./tests/server.sh up
server-down:
	./tests/server.sh down

.PHONY: test test-mailpit lint example docs server server-down
