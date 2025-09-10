# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Crops API', type: :request do
  path '/api/v1/crops' do
    get 'Lists crops' do
      tags 'Crops'
      produces 'application/vnd.api+json'
      parameter name: 'filter[approval_status]', in: :query, type: :string, required: false, description: 'Filter by approval status. Defaults to "approved".'

      response '200', 'successful' do
        schema type: :object,
               properties: {
                 data: {
                   type: :array,
                   items: {
                     type: :object,
                     properties: {
                       id: { type: :string },
                       type: { type: :string },
                       attributes: {
                         type: :object,
                         properties: {
                           name: { type: :string },
                           'en-wikipedia-url': { type: :string, format: 'uri', 'x-nullable': true },
                           perennial: { type: :boolean, 'x-nullable': true },
                           'median-lifespan': { type: :integer, 'x-nullable': true },
                           'median-days-to-first-harvest': { type: :integer, 'x-nullable': true },
                           'median-days-to-last-harvest': { type: :integer, 'x-nullable': true }
                         }
                       },
                       relationships: {
                         type: :object,
                         properties: {
                           plantings: { '$ref' => '#/components/schemas/relationship' },
                           parent: { '$ref' => '#/components/schemas/relationship' },
                           harvests: { '$ref' => '#/components/schemas/relationship' },
                           seeds: { '$ref' => '#/components/schemas/relationship' },
                           photos: { '$ref' => '#/components/schemas/relationship' }
                         }
                       }
                     }
                   }
                 }
               }

        let!(:crop) { FactoryBot.create(:crop) }
        run_test!
      end
    end
  end

  path '/api/v1/crops/{id}' do
    get 'Retrieves a crop' do
      tags 'Crops'
      produces 'application/vnd.api+json'
      parameter name: :id, in: :path, type: :string

      response '200', 'successful' do
        schema type: :object,
               properties: {
                 data: {
                   type: :object,
                   properties: {
                     id: { type: :string },
                     type: { type: :string },
                     attributes: {
                       type: :object,
                       properties: {
                         name: { type: :string },
                         'en-wikipedia-url': { type: :string, format: 'uri', 'x-nullable': true },
                         perennial: { type: :boolean, 'x-nullable': true },
                         'median-lifespan': { type: :integer, 'x-nullable': true },
                         'median-days-to-first-harvest': { type: :integer, 'x-nullable': true },
                         'median-days-to-last-harvest': { type: :integer, 'x-nullable': true }
                       }
                     },
                     relationships: {
                       type: :object,
                       properties: {
                         plantings: { '$ref' => '#/components/schemas/relationship' },
                         parent: { '$ref' => '#/components/schemas/relationship' },
                         harvests: { '$ref' => '#/components/schemas/relationship' },
                         seeds: { '$ref' => '#/components/schemas/relationship' },
                         photos: { '$ref' => '#/components/schemas/relationship' }
                       }
                     }
                   }
                 }
               }
        let(:crop) { FactoryBot.create(:crop) }
        let(:id) { crop.id }
        run_test!
      end
    end
  end
end
