require_relative 'chita_api'
require 'dry/validation'
require 'date'


class Invoicer < Dry::Validation::Contract
  params do
    required(:rut).filled(:string)
    required(:monto).filled(:string)
    required(:folio).filled(:string)
    required(:fecha).value(:string)
  end

  rule(:rut) do
    unless /^(\d{1,3}(?:\.\d{1,3}){2}-[\dkK])$/.match?(value)
      key.failure('Run con formato inválido...')
    end
  end

  rule(:monto) do
    unless /\d/.match?(value) && value.to_i >= 15000
      key.failure('Monto con formato inválido...')
    end
  end

  rule(:folio) do
    unless /\d/.match?(value) && value.to_i >= 1
      key.failure('Folio con formato inválido...')
    end
  end

  rule(:fecha) do
    input = Date.parse(value) rescue nil
    ftime = input.strftime("%Y-%m-%d") rescue nil
    unless input.is_a?(Date) && ftime.is_a?(String) && ftime == value && input >= Date.today
      key.failure('Fecha con formato inválido...')
    end
  end
end

puts "######################  CHITA API INVOICER #####################"
puts "Ingrese Rut del Deudor: (Con puntos,guión y digito verificador --> 11.222.333-4)"
rut = gets.strip.downcase
puts "Ingrese Monto a Solicitar: (Numero Entero --> 999999 y Mayor a 14999)"
monto = gets.strip.downcase
puts "Ingrese número de folio: (Numero Entero --> 999999)"
folio = gets.strip.downcase
puts "Ingrese Fecha de Vencimiento: (AAAA-MM-DD y Superior a Hoy):"
fecha = gets.strip.downcase

invoice = Invoicer.new
validations = invoice.call(
  rut: rut,
  #rut: '26351604-4',
  monto: monto,
  #monto: 156000,
  folio: folio,
  #folio: 58,
  fecha: fecha
)

unless validations.errors.any?
  new_invoice = ChitaApi.new(
    '76329692-K',
    rut,
    monto,
    folio,
    fecha
  )
  new_invoice.call
else
  validations.errors.to_h.each do |input, error|
    puts "Error en #{input}: #{error.first}"
  end
  puts "Intente nuevamente *** END ***"
end

