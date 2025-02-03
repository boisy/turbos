* TurbOS system definitions
               use       turbos.d

* F256 Jr. specific definitions
               use       turbo9sim.d

* F256 Jr. mapped I/O boundaries
MappedIOStart  set       $FF00
MappedIOEnd    set       $FFFF

* F256 Jr. ticks per second support
TkPerSec       set       60
