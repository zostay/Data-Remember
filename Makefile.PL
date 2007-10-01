use inc::Module::Install;

name     'Data-Remember';
all_from 'lib/Data/Remember.pm';

requires 'Carp';
requires 'DBM::Deep';
requires 'UNIVERSAL::require';
requires 'YAML::Syck';

auto_install;
WriteAll;
