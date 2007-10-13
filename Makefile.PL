use inc::Module::Install;

name     'Data-Remember';
all_from 'lib/Data/Remember.pm';

# TODO FIXME XXX I need to split up these requirements so that they are all
# recommended instead. Tests should be split and skipped if requirements are
# not available. 

requires 'DBM::Deep';
requires 'POE';
requires 'UNIVERSAL::require';
requires 'YAML::Syck';

auto_install;
WriteAll;
