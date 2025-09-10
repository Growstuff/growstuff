# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Plantings API', type: :request do
  path '/api/v1/plantings' do
    get 'Lists plantings' do
      tags 'Plantings'
      produces 'application/vnd.api+json'
      parameter name: 'filter[failed]', in: :query, type: :string, required: false
      parameter name: 'filter[sunniness]', in: :query, type: :string, required: false
      parameter name: 'filter[perennial]', in: :query, type: :string, required: false
      parameter name: 'filter[active]', in: :query, type: :string, required: false

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
                           slug: { type: :string },
                           'planted-at': { type: :string, format: 'date' },
                           failed: { type: :boolean },
                           finished: { type: :boolean },
                           'finished-at': { type: :string, format: 'date-time', 'x-nullable': true },
                           quantity: { type: :integer },
                           description: { type: :string, 'x-nullable': true },
                           sunniness: { type: :string, 'x-nullable': true },
                           'planted-from': { type: :string, 'x-nullable': true },
                           'expected-lifespan': { type: :integer, 'x-nullable': true },
                           'finish-predicted-at': { type: :string, format: 'date-time', 'x-nullable': true },
                           'first-harvest-date': { type: :string, format: 'date', 'x-nullable': true },
                           'last-harvest-date': { type: :string, format: 'date', 'x-nullable': true },
                           'crop-name': { type: :string },
                           'crop-slug': { type: :string },
                           thumbnail: { type: :string, format: :uri, 'x-nullable': true },
                           location: { type: :string, 'x-nullable': true },
                           longitude: { type: :number, format: :float, 'x-nullable': true },
                           latitude: { type: :number, format: :float, 'x-nullable': true }
                         }
                       },
                       relationships: {
                         type: :object,
                         properties: {
                           garden: { '$ref' => '#/components/schemas/relationship' },
                           crop: { '$ref' => '#/components/schemas/relationship' },
                           owner: { '$ref' => '#/components/schemas/relationship' },
                           photos: { '$ref' => '#/components/schemas/relationship' },
                           harvests: { '$ref' => '#/components/schemas/relationship' }
                         }
                       }
                     }
                   }
                 }
               }

        let!(:planting) { FactoryBot.create(:planting) }
        run_test!
      end
    end

    post 'Creates a planting' do
      tags 'Plantings'
      consumes 'application/vnd.api+json'
      produces 'application/vnd.api+json'
      parameter name: :planting, in: :body, schema: {
        type: :object,
        properties: {
          data: {
            type: :object,
            properties: {
              type: { type: :string },
              attributes: {
                type: :object,
                properties: {
                  description: { type: :string }
                }
              },
              relationships: {
                type: :object,
                properties: {
                  crop: {
                    type: :object,
                    properties: {
                      data: {
                        type: :object,
                        properties: {
                          type: { type: :string },
                          id: { type: :string }
                        },
                        required: ['type', 'id']
                      }
                    },
                    required: ['data']
                  },
                  garden: {
                    type: :object,
                    properties: {
                      data: {
                        type: :object,
                        properties: {
                          type: { type: :string },
                          id: { type: :string }
                        },
                        required: ['type', 'id']
                      }
                    },
                    required: ['data']
                  }
                },
                required: ['crop', 'garden']
              }
            },
            required: ['type', 'attributes', 'relationships']
          }
        },
        required: ['data']
      }

      response '201', 'created' do
        let(:member) { create(:member) }
        let(:token) do
          member.regenerate_api_token
          member.api_token.token
        end
        let(:Authorization) { "Token token=#{token}" }
        let(:crop) { create(:crop) }
        let(:garden) { create(:garden, owner: member) }
        let(:planting) { { data: { type: 'plantings', attributes: { description: 'My API planting' }, relationships: { crop: { data: { type: 'crops', id: crop.id } }, garden: { data: { type: 'gardens', id: garden.id } } } } } }
        run_test!
      end

      response '401', 'unauthorized' do
        let(:crop) { create(:crop) }
        let(:garden) { create(:garden) }
        let(:planting) { { data: { type: 'plantings', attributes: { description: 'My API planting' }, relationships: { crop: { data: { type: 'crops', id: crop.id } }, garden: { data: { type: 'gardens', id: garden.id } } } } } }
        run_test!
      end
    end
  end

  path '/api/v1/plantings/{id}' do
    get 'Retrieves a planting' do
      tags 'Plantings'
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
                         slug: { type: :string },
                         'planted-at': { type: :string, format: 'date' },
                         failed: { type: :boolean },
                         finished: { type: :boolean },
                         'finished-at': { type: :string, format: 'date-time', 'x-nullable': true },
                         quantity: { type: :integer },
                         description: { type: :string, 'x-nullable': true },
                         sunniness: { type: :string, 'x-nullable': true },
                         'planted-from': { type: :string, 'x-nullable': true },
                         'expected-lifespan': { type: :integer, 'x-nullable': true },
                         'finish-predicted-at': { type: :string, format: 'date-time', 'x-nullable': true },
                         'first-harvest-date': { type: :string, format: 'date', 'x-nullable': true },
                         'last-harvest-date': { type: :string, format: 'date', 'x-nullable': true },
                         'crop-name': { type: :string },
                         'crop-slug': { type: :string },
                         thumbnail: { type: :string, format: :uri, 'x-nullable': true },
                         location: { type: :string, 'x-nullable': true },
                         longitude: { type: :number, format: :float, 'x-nullable': true },
                         latitude: { type: :number, format: :float, 'x-nullable': true }
                       }
                     },
                     relationships: {
                       type: :object,
                       properties: {
                         garden: { '$ref' => '#/components/schemas/relationship' },
                         crop: { '$ref' => '#/components/schemas/relationship' },
                         owner: { '$ref' => '#/components/schemas/relationship' },
                         photos: { '$ref' => '#/components/schemas/relationship' },
                         harvests: { '$ref' => '#/components/schemas/relationship' }
                       }
                     }
                   }
                 }
               }
        let(:planting) { FactoryBot.create(:planting) }
        let(:id) { planting.id }
        run_test!
      end
    end

    patch 'Updates a planting' do
      tags 'Plantings'
      consumes 'application/vnd.api+json'
      produces 'application/vnd.api+json'
      parameter name: :id, in: :path, type: :string
      parameter name: :planting, in: :body, schema: {
        type: :object,
        properties: {
          data: {
            type: :object,
            properties: {
              type: { type: :string },
              id: { type: :string },
              attributes: {
                type: :object,
                properties: {
                  description: { type: :string }
                }
              }
            },
            required: ['type', 'id']
          }
        },
        required: ['data']
      }

      response '200', 'ok' do
        let(:member) { create(:member) }
        let(:token) do
          member.regenerate_api_token
          member.api_token.token
        end
        let(:Authorization) { "Token token=#{token}" }
        let(:planting_to_update) { create(:planting, owner: member) }
        let(:id) { planting_to_update.id }
        let(:planting) { { data: { type: 'plantings', id: id, attributes: { description: 'An updated planting' } } } }
        run_test!
      end

      response '401', 'unauthorized' do
        let(:planting_to_update) { create(:planting) }
        let(:id) { planting_to_update.id }
        let(:planting) { { data: { type: 'plantings', id: id, attributes: { description: 'An updated planting' } } } }
        run_test!
      end

      response '403', 'forbidden' do
        let(:member) { create(:member) }
        let(:token) do
          member.regenerate_api_token
          member.api_token.token
        end
        let(:Authorization) { "Token token=#{token}" }
        let(:other_member_planting) { create(:planting) }
        let(:id) { other_member_planting.id }
        let(:planting) { { data: { type: 'plantings', id: id, attributes: { description: 'An updated planting' } } } }
        run_test!
      end
    end

    delete 'Deletes a planting' do
      tags 'Plantings'
      parameter name: :id, in: :path, type: :string

      response '204', 'no content' do
        let(:member) { create(:member) }
        let(:token) do
          member.regenerate_api_token
          member.api_token.token
        end
        let(:Authorization) { "Token token=#{token}" }
        let(:planting_to_delete) { create(:planting, owner: member) }
        let(:id) { planting_to_delete.id }
        run_test!
      end

      response '401', 'unauthorized' do
        let(:planting_to_delete) { create(:planting) }
        let(:id) { planting_to_delete.id }
        run_test!
      end

      response '403', 'forbidden' do
        let(:member) { create(:member) }
        let(:token) do
          member.regenerate_api_token
          member.api_token.token
        end
        let(:Authorization) { "Token token=#{token}" }
        let(:other_member_planting) { create(:planting) }
        let(:id) { other_member_planting.id }
        run_test!
      end
    end
  end
end
