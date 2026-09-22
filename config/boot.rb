ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.

# NOTA: bootsnap deshabilitado en desarrollo local porque su extensión nativa
# (bs_fetch) falla al abrir archivos cuando la ruta del proyecto contiene
# caracteres no-ASCII (Windows). No afecta producción/Docker.
require "bootsnap/setup" unless ENV["CONDOTRACK_DISABLE_BOOTSNAP"]
