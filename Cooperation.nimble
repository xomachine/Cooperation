
version       = "0.1.0"
author        = "xomachine"
description   = "Resource manager for small cluster"
license       = "MIT"

srcDir = "src"
requires "nim >= 0.14.2"
requires "nesm"
requires "metaevents"
requires "jser"
bin    = @["cooperation"]
