# CESM "D_JRA_WD" payu configuration
CESM CICE6-WW3-DOCN-DATM-DROF-SLND-SGLC payu configuration. By default, this configuration will advance 1 year per model run.

**Warning**, this is an untested porting (to payu) of a hacked-together and untested CESM configuration. You're welcome to use this, but do so at your own risk. Note also that no effort has (yet) been put into optimising the PE layout of this configuration on Gadi - currently each model component simply runs sequentially and is allocated an entire node.
