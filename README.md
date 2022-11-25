# CESM D_JRA_WD<sup>*</sup> payu configuration
CESM CICE6-WW3-DOCN-DATM-DROF-SLND-SGLC payu configuration. By default, this configuration will advance 1 year per model run.

<sup>*</sup>This is not an actual CESM CIME compset. I've named it this based on the shorthand names of other compsets.

**Warning**, this is an untested payu configuration for a kluged-together and untested CESM configuration. You're welcome to use this, but do so at your own risk. Note also that no effort has (yet) been put into optimising the PE layout of this configuration on Gadi - currently each model component simply runs sequentially and is allocated an entire node.
