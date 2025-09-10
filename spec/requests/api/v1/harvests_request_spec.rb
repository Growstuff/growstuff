# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Harvests API', type: :request do
  path '/api/v1/harvests' do
    get 'Lists harvests' do
      tags 'Harvests'
      produces 'application/vnd.api+json'
      parameter name: 'filter[crop_id]', in: :query, type: :string, required: false
      parameter name: 'filter[planting_id]', in: :query, type: :string, required: false
      parameter name: 'filter[plant_part]', in: :query, type: :string, required: false
      parameter name: 'filter[owner_id]', in: :query, type: :string, required: false

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
                           'harvested-at': { type: :string, format: 'date' },
                           description: { type: :string, 'x-nullable': true },
                           unit: { type: :string, 'x-nullable': true },
                           'weight-quantity': { type: :string, 'x-nullable': true },
                           'weight-unit': { type: :string, 'x-nullable': true },
                           'si-weight': { type: :number, format: :float, 'x-nullable': true }
                         }
                       },
                       relationships: {
                         type: :object,
                         properties: {
                           crop: { '$ref' => '#/components/schemas/relationship' },
                           planting: { '$ref' => '#/components/schemas/relationship' },
                           owner: { '$ref' => '#/components/schemas/relationship' },
                           photos: { '$ref' => '#/components/schemas/relationship' }
                         }
                       }
                     }
                   }
                 }
               }

        let!(:harvest) { FactoryBot.create(:harvest) }
        run_test!
      end
    end

    post 'Creates a harvest' do
      tags 'Harvests'
      consumes 'application/vnd.api+json'
      produces 'application/vnd.api+json'
      parameter name: :harvest, in: :body, schema: {
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
                  planting: {
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
                required: ['planting']
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
        let(:planting) { create(:planting, owner: member) }
        let(:harvest) { { data: { type: 'harvests', attributes: { description: 'My API harvest' }, relationships: { planting: { data: { type: 'plantings', id: planting.id } } } } } }
        run_test!
      end

      response '401', 'unauthorized' do
        let(:planting) { create(:planting) }
        let(:harvest) { { data: { type: 'harvests', attributes: { description: 'My API harvest' }, relationships: { planting: { data: { type: 'plantings', id: planting.id } } } } } }
        run_test!
      end
    end
  end

  path '/api/v1/harvests/{id}' do
    get 'Retrieves a harvest' do
      tags 'Harvests'
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
                         'harvested-at': { type: :string, format: 'date' },
                         description: { type: :string, 'x-nullable': true },
                         unit: { type: :string, 'x-nullable': true },
                         'weight-quantity': { type: :string, 'x-nullable': true },
                         'weight-unit': { type: :string, 'x-nullable': true },
                         'si-weight': { type: :number, format: :float, 'x-nullable': true }
                       }
                     },
                     relationships: {
                       type: :object,
                       properties: {
                         crop: { '$ref' => '#/components/schemas/relationship' },
                         planting: { '$ref' => '#/components/schemas/relationship' },
                         owner: { '$ref' => '#/components/schemas/relationship' },
                         photos: { '$ref' => '#/components/schemas/relationship' }
                       }
                     }
                   }
                 }
               }
        let(:harvest) { FactoryBot.create(:harvest) }
        let(:id) { harvest.id }
        run_test!
      end
    end

    patch 'Updates a harvest' do
      tags 'Harvests'
      consumes 'application/vnd.api+json'
      produces 'application/vnd.api+json'
      parameter name: :id, in: :path, type: :string
      parameter name: :harvest, in: :body, schema: {
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
        let(:harvest_to_update) { create(:harvest, owner: member) }
        let(:id) { harvest_to_update.id }
        let(:harvest) { { data: { type: 'harvests', id: id, attributes: { description: 'An updated harvest' } } } }
        run_test!
      end

      response '401', 'unauthorized' do
        let(:harvest_to_update) { create(:harvest) }
        let(:id) { harvest_to_update.id }
        let(:harvest) { { data: { type: 'harvests', id: id, attributes: { description: 'An updated harvest' } } } }
        run_test!
      end

      response '403', 'forbidden' do
        let(:member) { create(:member) }
        let(:token) do
          member.regenerate_api_token
          member.api_token.token
        end
        let(:Authorization) { "Token token=#{token}" }
        let(:other_member_harvest) { create(:harvest) }
        let(:id) { other_member_harvest.id }
        let(:harvest) { { data: { type: 'harvests', id: id, attributes: { description: 'An updated harvest' } } } }
        run_test!
      end
    end

    delete 'Deletes a harvest' do
      tags 'Harvests'
      parameter name: :id, in: :path, type: :string

      response '204', 'no content' do
        let(:member) { create(:member) }
        let(:token) do
          member.regenerate_api_token
          member.api_token.token
        end
        let(:Authorization) { "Token token=#{token}" }
        let(:harvest_to_delete) { create(:harvest, owner: member) }
        let(:id) { harvest_to_delete.id }
        run_test!
      end

      response '401', 'unauthorized' do
        let(:harvest_to_delete) { create(:harvest) }
        let(:id) { harvest_to_delete.id }
        run_test!
      end

      response '403', 'forbidden' do
        let(:member) { create(:member) }
        let(:token) do
          member.regenerate_api_token
          member.api_token.token
        end
        let(:Authorization) { "Token token=#{token}" }
        let(:other_member_harvest) { create(:harvest) }
        let(:id) { other_member_harvest.id }
        run_test!
      end
    end
  end
end
