# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API docs' do
  subject(:docs) { response.parsed_body }

  before { get '/api-docs/v1/swagger.json' }

  def operations(path)
    docs['paths'].fetch(path)
  end

  def parameter_names(operation)
    operation['parameters'].pluck('name')
  end

  it { expect(response).to have_http_status(:ok) }

  it 'is OpenAPI 3' do
    expect(docs['openapi']).to start_with('3.')
  end

  it 'documents every endpoint of the API' do
    expect(docs['paths'].keys.map { |path| path.delete_suffix('/{id}') }.uniq).to match_array(Graphiti::Schema.generate[:endpoints].keys.map(&:to_s))
  end

  it 'only refers to schemas that exist' do
    refs = response.body.scan(%r{#/components/schemas/(\w+)}).flatten.uniq
    expect(docs['components']['schemas'].keys).to include(*refs)
  end

  describe 'a resource that can be written' do
    it 'documents creating' do
      expect(operations('/api/v1/plantings').keys).to include('post')
    end

    it 'documents changing' do
      expect(operations('/api/v1/plantings/{id}').keys).to include('patch')
    end

    it 'documents deleting' do
      expect(operations('/api/v1/plantings/{id}').keys).to include('delete')
    end

    it 'asks for a token to write' do
      expect(operations('/api/v1/plantings')['post']['security']).to eq([{ 'bearerAuth' => [] }])
    end

    it 'documents the attributes that can be set, dasherised' do
      body = operations('/api/v1/plantings')['post']['requestBody']['content']['application/vnd.api+json']['schema']
      expect(body.dig('properties', 'data', 'properties', 'attributes', 'properties').keys).to include('planted-at')
    end

    it 'leaves out the attributes that are worked out' do
      body = operations('/api/v1/plantings')['post']['requestBody']['content']['application/vnd.api+json']['schema']
      expect(body.dig('properties', 'data', 'properties', 'attributes', 'properties').keys).not_to include('slug')
    end

    it 'documents the relationships that can be set' do
      body = operations('/api/v1/plantings')['post']['requestBody']['content']['application/vnd.api+json']['schema']
      expect(body.dig('properties', 'data', 'properties', 'relationships', 'properties').keys).to contain_exactly('garden', 'crop')
    end
  end

  describe 'a resource that is read only' do
    it 'documents only reading' do
      expect(operations('/api/v1/crops').keys).to eq(['get'])
    end

    it 'documents only reading one' do
      expect(operations('/api/v1/crops/{id}').keys - ['parameters']).to eq(['get'])
    end
  end

  describe 'listing' do
    let(:list) { operations('/api/v1/plantings')['get'] }

    it 'documents filters, dasherised' do
      expect(parameter_names(list)).to include('filter[owner-id]')
    end

    it 'documents sorting' do
      expect(parameter_names(list)).to include('sort')
    end

    it 'documents including related records' do
      expect(parameter_names(list)).to include('include')
    end

    it 'documents paging' do
      expect(parameter_names(list)).to include('page[number]', 'page[size]')
    end
  end

  it 'documents searching crops' do
    expect(parameter_names(operations('/api/v1/crops/search')['get'])).to include('term')
  end

  describe 'the page that shows them' do
    before { get '/api-docs/index.html' }

    it { expect(response).to have_http_status(:ok) }
  end
end
