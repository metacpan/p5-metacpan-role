FROM perl:5.38

# Install system dependencies that might be needed for CPAN modules
RUN apt-get update && apt-get install -y \
    build-essential \
    libssl-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Carton
RUN cpanm Carton

RUN cpanm Dist::Zilla

# Author dependencies
RUN cpanm --notest Dist::Zilla::Plugin::AutoPrereqs \
Dist::Zilla::Plugin::InstallGuide \
Dist::Zilla::Plugin::MetaJSON \
Dist::Zilla::Plugin::MetaResources \
Dist::Zilla::Plugin::PkgVersion \
Dist::Zilla::Plugin::ReadmeAnyFromPod \
Dist::Zilla::PluginBundle::Basic \
Software::License::Perl_5

# Heavy weight
RUN cpanm --notest Catalyst::Runtime

# Actual depencencies
RUN cpanm --notest Carp \
CatalystX::Fastly::Role::Response \
ExtUtils::MakeMaker \
Moose::Role \
MooseX::Fastly::Role \
Net::Fastly \
Test::More

# Set working directory
WORKDIR /app

# Default command is bash shell
CMD ["/bin/bash"]