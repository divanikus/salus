require "spec_helper"

RSpec.describe Salus::Observable do
  let (:described_class) do
     Class.new do
       include Salus::Observable
       public :observers, :observers=
     end
   end

   let(:observer_set) { double(:observer_set) }
   subject { described_class.new }

   before(:each) do
     subject.observers = observer_set
   end

   it 'uses the given observer set' do
     expected          = Salus::ObserversSet.new
     subject.observers = expected
     expect(subject.observers).to eql expected
   end

   it 'delegates #add_observer' do
     expect(observer_set).to receive(:add).with(:observer, :update) { |v| v }
     expect(subject.add_observer(:observer)).to eq :observer
   end

   it 'delegates #with_observer' do
     expect(observer_set).to receive(:add).with(:observer, :update) { |v| v }
     expect(subject.with_observer(:observer)).to eq subject
   end

   it 'delegates #delete_observer' do
     expect(observer_set).to receive(:delete).with(:observer)
     subject.delete_observer(:observer)
   end

   it 'delegates #delete_observers' do
     expect(observer_set).to receive(:delete_all).with(no_args)
     subject.delete_observers
   end

   it 'delegates #count_observers' do
     expect(observer_set).to receive(:count).with(no_args)
     subject.count_observers
   end
end
