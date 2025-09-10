# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Activities API', type: :request do
  path '/api/v1/activities' do
    get 'Lists activities' do
      tags 'Activities'
      produces 'application/vnd.api+json'
      parameter name: 'filter[owner-id]', in: :query, type: :string, required: false
      parameter name: 'filter[garden-id]', in: :query, type: :string, required: false
      parameter name: 'filter[planting-id]', in: :query, type: :string, required: false
      parameter name: 'filter[category]', in: :query, type: :string, required: false

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
                           description: { type: :string },
                           category: { type: :string },
                           finished: { type: :boolean },
                           'due-date': { type: :string, format: 'date-time' }
                         }
                       },
                       relationships: {
                         type: :object,
                         properties: {
                           owner: { '$ref' => '#/components/schemas/relationship' },
                           garden: { '$ref' => '#/components/schemas/relationship' },
                           planting: { '$ref' => '#/components/schemas/relationship' }
                         }
                       }
                     }
                   }
                 }
               }

        let!(:activity) { FactoryBot.create(:activity, garden: create(:garden), planting: create(:planting)) }
        run_test!
      end
    end
  end

  path '/api/v1/activities/{id}' do
    get 'Retrieves an activity' do
      tags 'Activities'
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
                         description: { type: :string },
                         category: { type: :string },
                         finished: { type: :boolean },
                         'due-date': { type: :string, format: 'date-time' }
                       }
                     },
                     relationships: {
                       type: :object,
                       properties: {
                         owner: { '$ref' => '#/components/schemas/relationship' },
                         garden: { '$ref' => '#/components/schemas/relationship' },
                         planting: { '$ref' => '#/components/schemas/relationship' }
                       }
                     }
                   }
                 }
               }
        let(:activity) { FactoryBot.create(:activity, garden: create(:garden), planting: create(:planting)) }
        let(:id) { activity.id }
        run_test!
      end
    end
  end
end
