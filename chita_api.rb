require 'json'
require 'rest-client'
require 'date'

# Allows connecting to the Chita API and obtaining information
# to process and deliver an invoice quote.
class ChitaApi
  URL = 'https://chita.cl/api/v1/pricing/simple_quote'.freeze

  def initialize(client_dni, debtor_dni, document_amount, folio, expiration_date)
    @client_dni = client_dni
    @debtor_dni = debtor_dni
    @document_amount = document_amount
    @folio = folio 
    @expiration_date = expiration_date
  end 

  # External method for performing the api request .
  #
  # @return [String].
  # Example:
  # "Costo de financiamiento: $34.861 
  # Giro a recibir: $955.139 
  # Excedentes: $10.000.0"
  def call
    print_invoice
  end

  private

  # API request header
  #
  # @return [Hash].
  def headers
    {
      'content-type': "application/json",
      'x-api-key': "UVG5jbLZxqVtsXX4nCJYKwtt",
      'cache-control': "no-cache",
      'params': params
    }
  end

  # API request Params
  #
  # @return [Hash].
  def params
    {
      client_dni: @client_dni,
      debtor_dni: @debtor_dni,
      document_amount: @document_amount,
      folio: @folio,
      expiration_date: @expiration_date
    }
  end

  # Executing the Api Request
  #
  # @return [Hash].
  # Example:
  # {:document_rate=>1.39, :commission=>0.0, :advance_percent=>99.0}
  def obtain_response
    res = RestClient.get(ChitaApi::URL, headers)
    @response = JSON.parse(res, { symbolize_names: true })
  end

  # Diference in days from today to due date
  #
  # @return [Integer].
  def days_to_deadline
    now = Date.today 
    due = Date.parse(@expiration_date)
    (due - now).to_i + 1
  end
  
  # Amount for resolving operations for invoice
  #
  # @return [Integer].
  def invoice_ratio
    (@document_amount.to_i * (@response[:advance_percent]/100))
  end

  # Cost of operating the invoice with us
  #
  # @return [Integer].
  def financial_cost
    (
      invoice_ratio * (@response[:document_rate]/100) / 30 * days_to_deadline
    ).to_i
  end

  # Amount to be received by the issuer if it operates
  #
  # @return [Integer].
  def money_order
    (
      invoice_ratio - (financial_cost - @response[:commission].to_i)
    ).to_i
  end

  # Amount to receive when the invoice is settled
  #
  # @return [Integer].  
  def surpluses
    @document_amount.to_i - invoice_ratio
  end    

  # Invoice data processed
  #
  # @return [String].
  def print_invoice
    obtain_response
    print "Costo de financiamiento: $#{currency_formatter(financial_cost)} \n"
    print "Giro a recibir: $#{currency_formatter(money_order)} \n"
    print "Excedentes: $#{currency_formatter(surpluses)} \n"
  end

  # Currency formatter
  #
  # @return [String].
  def currency_formatter(amount)
    amount.to_s.gsub(/(\d)(?=(\d{3})+(?!\d))/, "\\1.")
  end

end



