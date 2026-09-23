
# Documentation

Namespaces: [main](#main)

---

# main

## Errors for 'main'

```js
// Thrown by every operation of this package.
+ error Error (connect, tls, auth, sender, recipient, rejected, protocol, timeout, closed, invalid) payload { message: String, reply_code: uint (0), reply: String (""), address: String ("") }
```

### Error

Thrown by every operation of this package.

- `connect`: the TCP connection could not be opened, or reading and writing failed.
- `tls`: the TLS handshake failed, its settings could not be used, or STARTTLS was required
  and the server does not offer it.
- `auth`: the server rejected the credentials, offers no mechanism this package speaks, or
  the credentials would have gone over a connection without TLS.
- `sender`: the server refused the sender (`MAIL FROM`).
- `recipient`: the server refused a recipient (`RCPT TO`); `address` holds which one.
- `rejected`: the server refused the message itself, at `DATA` or after it, or the message
  is larger than the server accepts.
- `protocol`: the server sent something this package did not expect.
- `timeout`: the server did not answer in time.
- `closed`: the connection is closed, or the server answered `421` to say it is closing it.
- `invalid`: the message or the settings cannot be used as they are: a missing sender or
  recipient, an address that is not valid, a line break in a header, or a URL that is not
  an SMTP URL.

`reply_code` holds the three digit SMTP code of the reply that caused the error, and 0 when
there was none. A code from 400 to 499 is temporary, so the same message may succeed later;
one from 500 up is permanent. `reply` holds the text of that reply.

## Enums for 'main'

```js
// How to log in.
+ enum AuthMethod { auto, plain, login }
// How the connection is protected with TLS.
+ enum Security { plain, starttls, starttls_optional, tls }
```

### AuthMethod

How to log in.

### Security

How the connection is protected with TLS.

## Functions for 'main'

```js
// Reads an `smtp://` or `smtps://` URL as a `Config`.
+ fn config_from_url(text: String, timeout_ms: uint (30000)) Config !Error
// Opens a connection to `host` and logs in when `username` is given.
+ fn connect(host: String, port: u16 (0), security: Security (Security.starttls), username: String (""), password: String (""), timeout_ms: uint (30000)) Client !Error
// Opens a connection described by an `smtp://` or `smtps://` URL; see `config_from_url`.
+ fn connect_url(text: String, timeout_ms: uint (30000)) Client !Error
// Opens a connection described by a `Config`: greets the server, switches to TLS as `security` says, and logs in when `username` is set.
+ fn connect_with(config: Config) Client !Error
// The date as RFC 5322 writes it, such as `Tue, 22 Sep 2026 14:07:09 +0000`.
+ fn format_date(date: DateTime) String
// Reads an address as it is written in a message: `ada@example.com`, `<ada@example.com>`, `Ada Lovelace <ada@example.com>` or `"Lovelace, Ada" <ada@example.com>`.
+ fn parse_address(text: String) Address !Error
// Connects, sends one message and closes the connection again. Returns what the server answered to the message, which often names the id it was queued under.
+ fn send(config: Config, message: Message) String !Error
```

### config_from_url

Reads an `smtp://` or `smtps://` URL as a `Config`.

`smtps://` is TLS from the first byte and `smtp://` switches to TLS with `STARTTLS`, which
the server has to offer. The URL may carry the credentials:
`smtp://user%40example.com:secret@smtp.example.com:587`. The query string can set
`security` (`plain`, `starttls`, `starttls_optional` or `tls`), `verify=false`,
`auth` (`plain` or `login`), `helo_name` and `allow_insecure_auth=true`.

```valk
let config = smtp.config_from_url("smtp://localhost:1025?security=plain") ! panic("%{E.message}")
```

### connect

Opens a connection to `host` and logs in when `username` is given.

A `port` of 0 picks the usual one for `security`. See `Config` for everything else, and
`connect_with` to set it.

```valk
let client = smtp.connect("smtp.example.com", 587, smtp.Security.starttls, "ada@example.com", "secret") ! panic("%{E.message}")
defer client.close()
```

### connect_url

Opens a connection described by an `smtp://` or `smtps://` URL; see `config_from_url`.

### connect_with

Opens a connection described by a `Config`: greets the server, switches to TLS as
`security` says, and logs in when `username` is set.

```valk
let client = smtp.connect_with(smtp.Config {
    host: "smtp.example.com"
    username: "ada@example.com"
    password: "secret"
}) ! panic("%{E.message}")
```

### format_date

The date as RFC 5322 writes it, such as `Tue, 22 Sep 2026 14:07:09 +0000`.

### parse_address

Reads an address as it is written in a message: `ada@example.com`, `<ada@example.com>`,
`Ada Lovelace <ada@example.com>` or `"Lovelace, Ada" <ada@example.com>`.

Throws `invalid` when the text is not one address. The address must be ASCII: a local part
of letters, digits, dots and ``!#$%&'*+-/=?^_`{|}~``, and a domain of letters, digits,
hyphens and dots, or an address literal such as `[192.0.2.1]`. The name may be any text,
except that it cannot hold a line break.

```valk
let address = smtp.parse_address("Ada <ada@example.com>") ! panic("%{E.message}")
println(address.name)   // Ada
println(address.email)  // ada@example.com
```

### send

Connects, sends one message and closes the connection again. Returns what the server
answered to the message, which often names the id it was queued under.

```valk
smtp.send(config, message) ! panic("%{E.message}")
```

## Classes for 'main'

```js
// An email address, with the name shown for it.
+ class Address {
    // The address itself, such as `ada@example.com`.
    + email: String
    // The display name, such as `Ada Lovelace`; empty when there is none.
    + name: String

    // Returns the domain: everything after the `@`.
    + fn domain() String
}
```

### Address

An email address, with the name shown for it.

#### email

The address itself, such as `ada@example.com`.

#### name

The display name, such as `Ada Lovelace`; empty when there is none.

#### domain

Returns the domain: everything after the `@`.

```js
// A file sent along with a message.
+ class Attachment {
    // The MIME type, such as `application/pdf` or `text/csv; charset=utf-8`.
    + content_type: String
    // The bytes of the file.
    + data: String
    // The name the file is shown and saved under.
    + filename: String
}
```

### Attachment

A file sent along with a message.

#### content_type

The MIME type, such as `application/pdf` or `text/csv; charset=utf-8`.

#### data

The bytes of the file.

#### filename

The name the file is shown and saved under.

```js
// A connection to a mail server, ready to send messages.
+ class Client {
    // Whether the client logged in.
    ~ authenticated: bool
    // Whether `close` was called, or the connection broke.
    ~ closed: bool
    // The settings this client was opened with.
    ~ config: Config
    // Prints every line sent and received when true; credentials are left out.
    + debug: bool
    // The extensions the server announced in its `EHLO` reply, by keyword in upper case, each with the rest of its line: `SIZE` with `"35882577"`, `AUTH` with `"PLAIN LOGIN"`. Empty for a server that only speaks `HELO`.
    ~ extensions: Map[String]
    // The first line of the server's greeting, without its code.
    ~ greeting: String
    // Whether the connection runs over TLS.
    ~ tls_active: bool

    // Says goodbye with `QUIT` and closes the connection. Does nothing when it is closed already.
    + fn close() void
    // Returns whether the server announced an extension, such as `SMTPUTF8` or `PIPELINING`.
    + fn has_extension(name: String) bool
    // Sends `NOOP` and returns whether the server answered, to check that the connection is still up.
    + fn ping() bool
    // Sends a message and returns what the server answered to it, which often names the id it was queued under.
    + fn send(message: Message) String !Error
    // Sends a message that is already rendered, with an envelope of its own: `from` is where bounces go, and `recipients` is who receives it, whatever the headers in `data` say.
    + fn send_raw(from: String, recipients: Array[String], data: String) String !Error
}
```

### Client

A connection to a mail server, ready to send messages.

Messages go one after another over the same connection. A client belongs to one coroutine
or one thread at a time.

#### authenticated

Whether the client logged in.

#### closed

Whether `close` was called, or the connection broke.

#### config

The settings this client was opened with.

#### debug

Prints every line sent and received when true; credentials are left out.

#### extensions

The extensions the server announced in its `EHLO` reply, by keyword in upper case, each
with the rest of its line: `SIZE` with `"35882577"`, `AUTH` with `"PLAIN LOGIN"`. Empty
for a server that only speaks `HELO`.

#### greeting

The first line of the server's greeting, without its code.

#### tls_active

Whether the connection runs over TLS.

#### close

Says goodbye with `QUIT` and closes the connection. Does nothing when it is closed
already.

#### has_extension

Returns whether the server announced an extension, such as `SMTPUTF8` or `PIPELINING`.

#### ping

Sends `NOOP` and returns whether the server answered, to check that the connection is
still up.

#### send

Sends a message and returns what the server answered to it, which often names the id it
was queued under.

The message goes to everyone in `to`, `cc` and `bcc`. When the server refuses one of
them, nothing is sent and `recipient` is thrown, naming that address.

#### send_raw

Sends a message that is already rendered, with an envelope of its own: `from` is where
bounces go, and `recipients` is who receives it, whatever the headers in `data` say.

Line breaks in `data` are sent as CRLF, and lines that start with a dot are escaped.

```js
// Everything needed to open a connection.
+ class Config {
    // Allows logging in over a connection without TLS. Leave it off unless the network in between is trusted, such as a relay on the same machine.
    + allow_insecure_auth: bool
    // The login mechanism.
    + auth: AuthMethod
    // The name this client introduces itself with in `EHLO`. Empty sends the address of this end of the connection, as `[192.0.2.1]`.
    + helo_name: String
    // Host name or address of the server.
    + host: String
    // The password to log in with.
    + password: String
    // Port of the server; 0 picks the usual one for `security`: 25 for `plain`, 587 for `starttls` and `starttls_optional`, 465 for `tls`.
    + port: u16
    // How the connection is protected.
    + security: Security
    // How long connecting may take, and how long any one reply may take, in milliseconds.
    + timeout_ms: uint
    // TLS settings, used by every security mode but `plain`.
    + tls: TlsOptions
    // The user name to log in with, or "" to send without logging in.
    + username: String

    // Returns `port`, or the usual port of `security` when it is 0.
    + fn port_or_default() u16
}
```

### Config

Everything needed to open a connection.

`connect` builds one of these, and `connect_with` and `send` take one. It holds the
password, so keep it out of logs.

#### allow_insecure_auth

Allows logging in over a connection without TLS. Leave it off unless the network in
between is trusted, such as a relay on the same machine.

#### auth

The login mechanism.

#### helo_name

The name this client introduces itself with in `EHLO`. Empty sends the address of this
end of the connection, as `[192.0.2.1]`.

#### host

Host name or address of the server.

#### password

The password to log in with.

#### port

Port of the server; 0 picks the usual one for `security`: 25 for `plain`, 587 for
`starttls` and `starttls_optional`, 465 for `tls`.

#### security

How the connection is protected.

#### timeout_ms

How long connecting may take, and how long any one reply may take, in milliseconds.

#### tls

TLS settings, used by every security mode but `plain`.

#### username

The user name to log in with, or "" to send without logging in.

#### port_or_default

Returns `port`, or the usual port of `security` when it is 0.

```js
// An email: who it is from and for, what it says, and what comes with it.
+ class Message {
    // The files that go with the message.
    + attachments: Array[Attachment]
    // Recipients who receive a copy without appearing anywhere in the message.
    + bcc: Array[String]
    // Recipients who receive a copy, visible to everyone.
    + cc: Array[String]
    // The date the message shows; null uses the moment it is rendered.
    + date: ?DateTime
    // The sender. It is also the address bounces go back to.
    + from: String
    // More headers, such as `List-Unsubscribe` or `X-Priority`, by name. The headers this class writes itself cannot be set here.
    + headers: Map[String]
    // The HTML body. With `text` as well, the message carries both and the mail client shows the one it prefers.
    + html: String
    // The `Message-ID` header, such as `<id@example.com>`. Empty makes one up when the message is rendered, and keeps it here, so that sending the message again sends the same id.
    + message_id: String
    // The address replies go to, when it is not `from`.
    + reply_to: String
    // The subject line.
    + subject: String
    // The plain text body.
    + text: String
    // The main recipients.
    + to: Array[String]

    // Adds a file with its name, MIME type and bytes.
    + fn attach(filename: String, content_type: String, data: String) void
    // Adds the file at `path`, under its own name.
    + fn attach_file(path: String, content_type: String ("")) void !Error
    // Returns the addresses the message is delivered to: `to`, `cc` and `bcc`, without the names and without doubles.
    + fn recipients() Array[String] !Error
    // Returns the message as it goes over the wire: headers and body with CRLF line breaks, no line longer than 998 characters, and everything outside ASCII encoded.
    + fn render() String !Error
}
```

### Message

An email: who it is from and for, what it says, and what comes with it.

Addresses are written the way they appear in a mail client: `ada@example.com` or
`Ada Lovelace <ada@example.com>`. Recipients in `bcc` receive the message without appearing
in it.

```valk
let message = smtp.Message {
    from: "Ada <ada@example.com>"
    to: .{ "bob@example.com" }
    subject: "The report"
    text: "It is attached."
}
message.attach("report.csv", "text/csv", "a,b\n1,2\n")
```

#### attachments

The files that go with the message.

#### bcc

Recipients who receive a copy without appearing anywhere in the message.

#### cc

Recipients who receive a copy, visible to everyone.

#### date

The date the message shows; null uses the moment it is rendered.

#### from

The sender. It is also the address bounces go back to.

#### headers

More headers, such as `List-Unsubscribe` or `X-Priority`, by name. The headers this
class writes itself cannot be set here.

#### html

The HTML body. With `text` as well, the message carries both and the mail client
shows the one it prefers.

#### message_id

The `Message-ID` header, such as `<id@example.com>`. Empty makes one up when the message is
rendered, and keeps it here, so that sending the message again sends the same id.

#### reply_to

The address replies go to, when it is not `from`.

#### subject

The subject line.

#### text

The plain text body.

#### to

The main recipients.

#### attach

Adds a file with its name, MIME type and bytes.

#### attach_file

Adds the file at `path`, under its own name.

An empty `content_type` is taken from the file extension, and is
`application/octet-stream` for an extension `fs.mime_type` does not know. Throws
`invalid` when the file cannot be read.

#### recipients

Returns the addresses the message is delivered to: `to`, `cc` and `bcc`, without the
names and without doubles.

Throws `invalid` when one of them is not a valid address.

#### render

Returns the message as it goes over the wire: headers and body with CRLF line breaks,
no line longer than 998 characters, and everything outside ASCII encoded.

Throws `invalid` when the message has no sender or no recipient, an address is not
valid, or a header holds a line break, which could otherwise smuggle in headers of its
own.

```js
// TLS settings for a connection.
+ class TlsOptions {
    // A directory of more certificate authorities to trust.
    + ca_dir: ?String
    // A PEM file with more certificate authorities to trust.
    + ca_file: ?String
    // Whether the certificate of the server is checked.
    + verify: bool
}
```

### TlsOptions

TLS settings for a connection.

The defaults verify the server certificate against the system CA bundle, which is what a
mail provider with a certificate from a public CA needs. A server with a self-signed
certificate needs its certificate in `ca_file`, or `verify: false` to check nothing, which
leaves the connection open to a machine in the middle.

The certificate is checked against the host that was connected to. Client certificates are
not supported.

#### ca_dir

A directory of more certificate authorities to trust.

#### ca_file

A PEM file with more certificate authorities to trust.

#### verify

Whether the certificate of the server is checked.
