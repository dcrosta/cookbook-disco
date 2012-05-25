maintainer       "Dan Crosta"
maintainer_email "dcrosta@late.am"
license          "BSD"
description      "Installs/Configures Disco"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.0"

depends "python", ">= 1.0.6"
depends "simple_iptables", ">= 0.1.0"
depends "build-essential", ">= 1.0.0"

supports "debian", ">= 6.0"
