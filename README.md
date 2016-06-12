# coverd

[![Go to coverd](https://img.shields.io/dub/v/coverd.svg)](https://code.dlang.org/packages/coverd)
[![Go to coverd](https://img.shields.io/dub/dt/coverd.svg)](https://code.dlang.org/packages/coverd)

Code coverage HTML reporter for D coverage listings.
This project is intented to easy generation of coverage reports for Continous Integration tools, for example put AppVeyor artifacts after build, exposing the coverage results.

Usage:

    ./coverd

All `source-*.lst` files will be processed to generate a simple `coverage.html` HTML report with coverage results.
