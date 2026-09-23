# valk-smtp

Sending email from [Valk](https://valk-lang.dev): an SMTP client with STARTTLS, TLS and login,
and a message builder that writes proper MIME — text and HTML bodies, attachments, and names and
subjects in any language. Purely written in Valk, with no os-package dependencies.

Requires Valk 0.7.0 or newer.

## Install

```
vman install github.com/ctxcode/valk-smtp
```

## Example

```rust
use smtp

let message = smtp.Message {
    from: "Ada Lovelace <ada@example.com>"
    to: .{ "Charles Babbage <charles@example.com>" }
    cc: .{ "mary@example.com" }
    bcc: .{ "archive@example.com" }          // receives it, appears nowhere in it
    subject: "Notes on the Analytical Engine"
    text: "Charles,\n\nThe notes are attached.\n\nAda"
    html: "<p>Charles,</p><p>The notes are attached.</p><p>Ada</p>"
}
message.attach("notes.csv", "text/csv", "step,value\n1,0.5\n")
message.attach_file("diagram.png") ! panic("%{E.message}")    // type from the extension

let config = smtp.Config {
    host: "smtp.example.com"                // STARTTLS on port 587 by default
    username: "ada@example.com"
    password: "secret"
}
smtp.send(config, message) ! panic("Not sent: %{E.message}")
```

`smtp.send` connects, sends and says goodbye. To send several messages, keep the connection:

```rust
let client = smtp.connect_with(config) ! panic("%{E.message}")
defer client.close()
each messages as message {
    client.send(message) ! println("Not sent to %{message.to.join(", ")}: %{E.message}")
}
```

## Messages

Addresses are written as a mail client shows them: `ada@example.com`, `Ada <ada@example.com>`,
or `"Lovelace, Ada" <ada@example.com>`, and `Lovelace, Ada <ada@example.com>` works as well since
every item of `to` is one address. `smtp.parse_address(text)` checks one the same way and hands
back its `name` and `email`.

What `render()` does for you, and `send` calls it:

- `Date`, `Message-ID` and `MIME-Version` are added. The id is made up once and kept in
  `message.message_id`, so a retry sends the same id; set `date` or `message_id` to choose them.
- `text` and `html` together become a `multipart/alternative`; attachments make it a
  `multipart/mixed`, each file in base64.
- A subject, header or name outside ASCII is written as RFC 2047 encoded-words, and an
  attachment name as RFC 2231. A body outside ASCII or with long lines goes as quoted-printable,
  or base64 when it is mostly non-ASCII, with `charset=utf-8`.
- Line breaks become CRLF, long headers are folded, and no line is longer than 998 characters.
  A body that is the whole message ends with a line break, since that is how SMTP ends it.
- Bcc recipients get the message through the envelope and are never written in it.

A line break in a subject, header, name or file name would let whoever wrote it add headers
of their own — a `Bcc` to a stranger, say. `render` refuses such a message with `invalid`
instead of cleaning it up, and so it does for an address that is not valid.

More headers go in `headers`, by name: `message.headers.set("List-Unsubscribe", "<mailto:unsubscribe@example.com>")`.
The ones the message writes itself (`From`, `Subject`, `Content-Type`, ...) are set through
their properties instead. `message.render()` returns the whole message as text, for a look at
what goes out or to store it.

## Connecting

```rust
// host, port (0 is the usual one for the mode), security, username, password, timeout
let client = smtp.connect("smtp.example.com", 0, smtp.Security.tls, "ada@example.com", "secret") ! panic("%{E.message}")

// Or from a URL: smtps:// is TLS, smtp:// is STARTTLS
let client = smtp.connect_url("smtps://ada\%40example.com:secret@smtp.example.com") ! panic("%{E.message}")

// Or from settings
let client = smtp.connect_with(smtp.Config { host: "localhost", port: 1025, security: smtp.Security.plain }) ! panic("%{E.message}")
```

| `security` | what happens | usual port |
| --- | --- | --- |
| `starttls` (default) | plain text first, then TLS with `STARTTLS`; fails when the server does not offer it | 587 |
| `starttls_optional` | `STARTTLS` when offered, plain text when not | 587 |
| `tls` | TLS from the first byte, also called SMTPS or implicit TLS | 465 |
| `plain` | no TLS at all, for a relay on the same machine or a test server | 25 |

A URL query can set `security`, `verify=false`, `auth`, `helo_name` and
`allow_insecure_auth=true`: `smtp://localhost:1025?security=plain`.

With a `username`, the client logs in with `AUTH PLAIN` or `AUTH LOGIN`, whichever the server
offers (`auth: smtp.AuthMethod.login` picks one). It only sends a password over TLS;
`allow_insecure_auth: true` lifts that for a network you trust.

The client introduces itself in `EHLO` with `helo_name`, or with the address of its own end of
the connection, as `[192.0.2.1]`, and falls back to `HELO` for a server that has no `EHLO`.
`client.extensions` holds what the server announced, and `client.has_extension("SMTPUTF8")`
asks for one. `debug: true` prints the conversation, credentials left out.

### TLS

The certificate of the server is checked against the system certificate authorities and the
host name, which is what a mail provider needs. For a server with a certificate of its own:

```rust
tls: .{ ca_file: "/etc/ssl/mail.crt" }   // trust this authority as well
tls: .{ verify: false }                  // check nothing, open to a machine in the middle
```

After `STARTTLS` the client throws away what the server said before and asks again, and it
refuses a server that sends anything between agreeing to `STARTTLS` and the handshake, since an
attacker in the middle could have put it there. Client certificates are not supported.

## Sending

`client.send(message)` sends `MAIL FROM` (with `SIZE` when the server announces it), a
`RCPT TO` for everyone in `to`, `cc` and `bcc` (each address once), and the message with every
line that starts with a dot escaped. Every message after the first on a connection starts
with `RSET`. It returns the server's answer, which usually names the id the message was queued
under.

When the server refuses one recipient, nothing is sent and `recipient` is thrown with the
address in `E.address`; the connection stays usable. `client.send_raw(from, recipients, data)`
sends a message you rendered yourself with an envelope of your own, such as a bounce address
that differs from `From`.

## Errors

Everything throws `smtp.Error`. `E.reply_code` holds the SMTP code of the reply that caused
it (0 when there was none) and `E.reply` its text. A code from 400 to 499 is temporary: the same
message may go through later.

| code | when |
| --- | --- |
| `connect` | the connection could not be opened, or the server refused it in its greeting |
| `tls` | the TLS handshake failed, or STARTTLS was required and not offered |
| `auth` | the login was refused, the server offers no mechanism in common, or there is no TLS |
| `sender` | the server refused the sender |
| `recipient` | the server refused a recipient; `E.address` says which |
| `rejected` | the server refused the message itself, or it is larger than the server's `SIZE` |
| `protocol` | the server sent something that is not SMTP |
| `timeout` | the server did not answer within `timeout_ms` |
| `closed` | the connection is closed, or the server closed it with a `421` |
| `invalid` | the message or settings cannot be used: no recipients, a bad address, a line break in a header |

```rust
client.send(message) ! {
    if error_is(E.code, recipient) : println("No such mailbox: " + E.address)
    else if E.reply_code >= 400 && E.reply_code < 500 : println("Try again later: " + E.message)
    else : println(E.message)
}
```

## Development

`make server` starts two [Mailpit](https://mailpit.axllent.org) servers in docker, which
accept every message and show it in a web page and an API: SMTP on 2525 with STARTTLS on offer
(web on http://localhost:8525), and SMTP over TLS on 2465 (web on http://localhost:8526), both
with a self-signed certificate generated into `tests/certs`. `make server-down` removes them.

`make test` runs the suite. Most of it talks to a scripted SMTP server that runs inside the test
process and checks the exact conversation, so it needs nothing installed; the tests named
`Mailpit: ...` send real mail to the servers above and read it back through the API. When the
servers are not running, `Mailpit: the servers are running` fails and says so.
`make test-mailpit` runs those alone, and `SKIP_MAILPIT=1 make test` skips them where docker is
not at hand. `make example` prints a rendered message and sends it to Mailpit, `make lint`
checks the sources and `make docs` regenerates the API documentation. Override the compiler with
`make vc=/path/to/valk test`.

## Not supported

- Internationalized addresses (`SMTPUTF8`): the address itself must be ASCII. Names, subjects,
  bodies and file names can hold any text.
- Login mechanisms other than `PLAIN` and `LOGIN`, such as `XOAUTH2` or `CRAM-MD5`.
- Client certificates for TLS, since `valk.net` has no client-side certificate setting yet.
- `PIPELINING`, `CHUNKING` and 8-bit transfer: commands go one at a time and bodies are encoded
  to 7-bit, which every server takes.
- Delivery status notifications (`DSN`) and partial delivery: a refused recipient stops the
  whole message.
- Inline images referenced from the HTML by `cid:` (`multipart/related`), and signing (DKIM,
  S/MIME). DKIM belongs to the relay that sends the mail on, in most setups.
- Delivering straight to the recipient's server by its MX record: send through a relay or a
  mail provider.
