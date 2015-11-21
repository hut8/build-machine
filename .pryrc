# -*-ruby-*-
if defined? Rails
  include FactoryGirl::Syntax::Methods if defined? FactoryGirl
  def rl!
    reload!
    FactoryGirl.reload if defined? FactoryGirl
    puts 'Reloaded.'
    true
  end
end

begin
  require 'awesome_print'
  Pry.config.print = proc { |output, value| output.puts value.ai }
rescue LoadError
  puts 'no awesome_print :('
end
