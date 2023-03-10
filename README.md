# Experimental Payu configuration for 1 deg CICE6-WW3-docn-datm-drof configuration using CMEPS with the CESM driver

data ocean (docn) = HadOIBl climatology

data atmosphere (datm) = JRA v1.3 (NB: not JRA55-do), 1958-2016, no-leap calendar

data runoff (drof) = JRA v1.1 (NB: not JRA55-do), 1958-2016, no-leap calendar

Note:
- **This is an untested Payu configuration for a kluged-together and untested CESM configuration**. This configuration and the executable it uses were kluged together from an officially-unsupported CESM configuration (The CIME GMOM_JRA_WD "compset"). Details of the kluging to build the executable can be found in the [build directory](https://github.com/COSIMA/CICE6-WW3/tree/main/build) of this repo. 
- This configuration uses a Payu driver that does not currently exist in the main Payu repo. We're working to include it, but in the meantime those wanting to play with this configuration will need to use the version of Payu in [this](https://github.com/dougiesquire/payu/tree/cesm_cmeps) branch.
- No effort has (yet) been put into optimising the PE layout of this configuration on Gadi - currently each model component simply runs sequentially and is allocated an entire node.
- By default, this configuration will advance 1 year per model run
