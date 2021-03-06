defmodule DBI.PostgreSQL do
  defstruct conn: nil

  @moduledoc """
   This module allows to connect to a PostgreSQL database
  """

  alias :pgsql, as: P

  @type connection :: any
  @type error :: DBI.PostgreSQL.Error

  @typep connection_option :: {:host, String.t} |
                              {:username, String.t} |
                              {:password, String.t} |
                              {:database, String.t} |
                              {:port, :inet.port_number} |
                              {:ssl, boolean | :required} |
                              {:ssl_opts, [:ssl.ssl_option]} |
                              {:timeout, timeout} |
                              {:async, pid}
  @type connection_options :: [connection_option]

  @doc """
  Connect to a PostgreSQL database.

  Supported options:

  * `host` — hostname to connect to. "localhost" by default
  * `username` — username. Defaults to `System.get_env("USER")`
  * `password` — password. Empty by default
  * `database` — database name
  * `port` — TCP port to connect to. 5432 by default
  * `ssl` — SSL requirement, `true`, `false` or `:required`. `false` by default
  * `ssl_options` — See `ssl` module documentation
  * `timeout`— Timeout in milliseconds. 5000 by default.
  * `async` — send async notices and notifications to a pid (epgsql-specific)
  """
  @spec connect(connection_options) :: {:ok, connection} | {:ok, error}
  def connect(opts) do
     host = to_char_list(opts[:host] || "localhost")
     args = [host]
     unless is_nil(opts[:username]) do
       args = [to_char_list(opts[:username])|args]
     end
     unless is_nil(opts[:password]) do
       args = [to_char_list(opts[:password])|args]
     end
     options = [
                 database: if is_nil(opts[:database]) do
                   :undefined
                 else
                   to_char_list(opts[:database])
                 end,
                 port: opts[:port] || 5432,
                 ssl: opts[:ssl] || false,
                 ssl_opts: opts[:ssl_opts] || :undefined,
                 timeout: opts[:timeout] || 5000,
                 async: opts[:async] || :undefined
               ]
     case apply(P, :connect, Enum.reverse([options|args])) do
       {:ok, conn} -> {:ok, %__MODULE__{conn: conn}}
       {:error, :invalid_authorization_specification} ->
         {:error,
          %DBI.PostgreSQL.Error{
            severity: :error, code: "28000",
            description: "Invalid authorization specification"}}
       {:error, :invalid_password} ->
         {:error,
          %DBI.PostgreSQL.Error{
             severity: :error, code: "28P01",
             description: "Invalid password"}}
       {:error, error} when is_binary(error) ->
         {:error, %DBI.PostgreSQL.Error{
           severity: :error, code: error,
           description: "Can't connect"}}
     end
  end

  @doc """
  Connect to a PostgreSQL database. Raises an exception if unsuccessful.

  For options description, read `DBI.PostgreSQL.connect/1` documentation.
  """
  @spec connect!(connection_options) :: connection | no_return
  def connect!(opts) do
    case connect(opts) do
      {:ok, conn} -> conn
      {:error, error} -> raise error
    end
  end

  @doc """
  Close the connection
  """
  @spec close(connection) :: :ok
  def close(%__MODULE__{conn: conn}) do
    P.close(conn)
    :ok
  end
end
