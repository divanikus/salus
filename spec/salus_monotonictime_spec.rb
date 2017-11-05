require "spec_helper"

RSpec.describe Salus::MonotonicTime do
   it 'it increases' do
     now = Salus::MonotonicTime.get
     sleep 1
     expect(Salus::MonotonicTime.get - now).to be >= 1.0
   end
end
