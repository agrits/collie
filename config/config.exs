import Config

if config_env() == "prod" do
  config :collie, elixir_ebin: "/usr/local/lib/elixir/lib/elixir/ebin"
else
  config :collie, elixir_ebin: "~/.asdf/installs/elixir/1.13.4-otp-25/lib/elixir/ebin/Elixir"
end
