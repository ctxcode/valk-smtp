
# Documentation

Namespaces: [main](#main)

---

# main

## Errors for 'main'

```js
// Thrown by every operation of this package.
+ error Error (connect, tls, auth, sender, recipient, rejected, protocol, timeout, closed, invalid) payload { message: String, reply_code: uint (0), reply: String (""), address: String ("") }
```

## Enums for 'main'

```js
// How to log in.
+ enum AuthMethod { auto, plain, login }
// How the connection is protected with TLS.
+ enum Security { plain, starttls, starttls_optional, tls }
```

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
