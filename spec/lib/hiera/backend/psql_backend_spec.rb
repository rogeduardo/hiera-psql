require 'spec_helper'
require 'hiera/backend/psql_backend'

class Hiera
  module Backend
    describe Psql_backend do
      before do
        Config.load({'psql'=>'asdfas'})
        Hiera.stub :debug
        Hiera.stub :warn

        @connection_mock = double('connection').as_null_object
        Psql_backend.should_receive(:connection).any_number_of_times.and_return(@connection_mock)

        @sql_query = 'SELECT value FROM config WHERE path=$1 AND key=$2'

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
          Backend.should_receive(:datasources).and_yield(['one']).and_yield(['two'])

          @connection_mock.should_receive(:exec).once.ordered.with(@sql_query, [['one'], anything()])
          @connection_mock.should_receive(:exec).once.ordered.with(@sql_query, [['two'], anything()])

          @backend.lookup(:key, {}, nil, :priority)
        end

        it 'should pick data earliest source that has it for priority searches' do
          Backend.should_receive(:datasources).and_yield(['one']).and_yield(['two'])

          @connection_mock.should_receive(:exec).once.ordered.with(@sql_query, [['one'], anything()]).and_yield([{'value'=>'"patate"', 'other_value'=>'asdf'}])
          @connection_mock.should_receive(:exec).once.ordered.with(@sql_query, [['two'], anything()]).and_yield([])

          @backend.lookup(:key, {}, nil, :priority).should == 'patate'
        end


        it 'should return nil for missing path/value' do
          Backend.should_receive(:datasources).with(:scope, :override).and_yield(['one'])

          @connection_mock.should_receive(:exec).once.ordered.with(@sql_query, [['one'], 'key']).and_yield([])

          @backend.lookup('key', :scope, :override, :priority)
        end

        it 'should build an array of all data sources for array searches' do
          Backend.should_receive(:datasources).and_yield(['one']).and_yield(['two'])

          @connection_mock.should_receive(:exec).once.ordered.with(@sql_query, [['one'], anything()]).and_yield([{'value'=>'"answer"'}])
          @connection_mock.should_receive(:exec).once.ordered.with(@sql_query, [['two'], anything()]).and_yield([{'value'=>'"answer"'}])

          @backend.lookup(:key, {}, nil, :array).should == ['answer', 'answer']
        end

        it 'should ignore empty hash of data sources for hash searches' do
          Backend.should_receive(:datasources).and_yield(['one']).and_yield(['two'])

          @connection_mock.should_receive(:exec).once.ordered.with(@sql_query, [['one'], anything()]).and_yield([{'value'=>'{}'}])
          @connection_mock.should_receive(:exec).once.ordered.with(@sql_query, [['two'], anything()]).and_yield([{'value'=>'{"a":"answer"}'}])

          @backend.lookup(:key, {}, nil, :hash).should == {'a'=>'answer'}
        end

        it 'should build a merged hash of data sources for hash searches' do
          Backend.should_receive(:datasources).and_yield(['one']).and_yield(['two'])

          @connection_mock.should_receive(:exec).once.ordered.with(@sql_query, [['one'], anything()]).and_yield([{'value'=>'{"a":"answer"}'}])
          @connection_mock.should_receive(:exec).once.ordered.with(@sql_query, [['two'], anything()]).and_yield([{'value'=>'{"b":"answer", "a":"wrong"}'}])

          @backend.lookup(:key, {}, nil, :hash).should == {'a'=>'answer', 'b'=>'answer'}
        end

        it 'should fail when trying to << a Hash' do
          Backend.should_receive(:datasources).and_yield(['one']).and_yield(['two'])

          @connection_mock.should_receive(:exec).once.ordered.with(@sql_query, [['one'], anything()]).and_yield([{'value'=>'["a","answer"]'}])
          @connection_mock.should_receive(:exec).once.ordered.with(@sql_query, [['two'], anything()]).and_yield([{'value'=>'{"a":"answer"}'}])

          expect {
            @backend.lookup(:key, {}, nil, :array)
          }.to raise_error(Exception, 'Hiera type mismatch: expected Array and got Hash')
        end

        it 'should fail when trying to merge an Array' do
          Backend.should_receive(:datasources).and_yield(['one']).and_yield(['two'])

          @connection_mock.should_receive(:exec).once.ordered.with(@sql_query, [['one'], anything()]).and_yield([{'value'=>'{"a":"answer"}'}])
          @connection_mock.should_receive(:exec).once.ordered.with(@sql_query, [['two'], anything()]).and_yield([{'value'=>'["a","answer"]'}])

          expect {
            @backend.lookup(:key, {}, nil, :hash)
          }.to raise_error(Exception, 'Hiera type mismatch: expected Hash and got Array')
        end

        it 'should parse the answer for scope variables' do
          Backend.should_receive(:datasources).and_yield(['one'])

          @connection_mock.should_receive(:exec).once.ordered.with(@sql_query, [['one'], anything()]).and_yield([{'value'=>'"test_%{rspec}"'}])

          @backend.lookup(:key, {'rspec'=>'test'}, nil, :priority).should == 'test_test'
        end

        it 'should retain the data types found in value' do
          Backend.should_receive(:datasources).exactly(3).and_yield(['one'])

          @connection_mock.should_receive(:exec).once.ordered.with(@sql_query, [['one'], anything()]).and_yield([{'value'=>'"string"'}])
          @connection_mock.should_receive(:exec).once.ordered.with(@sql_query, [['one'], anything()]).and_yield([{'value'=>'true'}])
          @connection_mock.should_receive(:exec).once.ordered.with(@sql_query, [['one'], anything()]).and_yield([{'value'=>'1'}])

          @backend.lookup('stringval', {}, nil, :priority).should == 'string'
          @backend.lookup('boolval', {}, nil, :priority).should == true
          @backend.lookup('numericval', {}, nil, :priority).should == 1
        end
      end
    end
  end
end
