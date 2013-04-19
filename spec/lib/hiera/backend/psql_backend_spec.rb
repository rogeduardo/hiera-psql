require 'spec_helper'
require 'hiera/backend/psql_backend'

class Hiera
  module Backend
    describe Psql_backend do
      before do
        #Config.load({'psql'=>'asdfas'})
        Hiera.stub :debug
        Hiera.stub :warn
        @backend = Psql_backend.new
      end

      describe '#initialize' do
        it 'should print debug through Hiera' do
          Hiera.should_receive(:debug).with('Hiera PostgreSQL backend starting')
          Psql_backend.new
        end
      end

      describe '#lookup' do
        it 'should look for data in all sources' do
          Backend.should_receive(:datasources).and_yield(["one"]).and_yield(["two"])

          connection_mock = double.as_null_object
          Psql_backend.should_receive(:connection).twice.and_return(connection_mock)
          connection_mock.should_receive(:exec).once.ordered.with(anything(), [["one"], anything()])
          connection_mock.should_receive(:exec).once.ordered.with(anything(), [["two"], anything()])

          @backend.lookup('key', {}, nil, :priority)
        end

        #it 'should pick data earliest source that has it for priority searches' do
        #  Backend.should_receive(:datasources).and_yield(["one"])#.and_yield(["two"])
        #
        #  connection_mock = double('connection').as_null_object
        #  #result_mock = double('result').as_null_object
        #  Psql_backend.should_receive(:connection).once.and_return(connection_mock)
        #  connection_mock.should_receive(:exec).once.ordered.with(anything(), [['one'], anything()]).and_yield({'value'=>'"patate"'})
        #
        #  #result_mock.should_receive(:first).once.ordered.and_return({'value'=>'"patate"'})
        #  #connection_mock.should_receive(:exec).once.ordered.with(anything(), [["two"], anything()]).and_return result_mock
        #  #result_mock.should_receive(:first).once.ordered.and_return nil
        #
        #  @backend.lookup('key', {}, nil, :priority).should == 'patate'
        #end


        #it 'should return nil for missing path/value' do
        #  mock_source = double.as_null_object
        #  Backend.should_receive(:datasources).with(:scope, :override).and_yield(mock_source)
        #
        #  described_class.should_receive(:exec).with(:query, :params).and_return(double.as_null_object)
        #
        #
        #  @backend.lookup(:key, :scope, :override, :resolution_type)
        #end
        #
        #it 'should build an array of all data sources for array searches' do
        #  # todo
        #  @backend.lookup("key", {}, nil, :array).should == ["answer", "answer"]
        #end
        #
        #it 'should build an array of all data sources for array searches' do
        #  # todo
        #  @backend.lookup("key", {}, nil, :hash).should == {"a" => "answer"}
        #end
        #
        #it 'should parse the answer for scope variables' do
        #  # todo
        #  @backend.lookup("key", {"rspec" => "test"}, nil, :priority).should == "test_test"
        #end
      end
    end
  end
end
