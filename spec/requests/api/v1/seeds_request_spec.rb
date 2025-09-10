# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Seeds API', type: :request do
  path '/api/v1/seeds' do
    get 'Lists seeds' do
      tags 'Seeds'
      produces 'application/vnd.api+json'
      parameter name: 'filter[crop]', in: :query, type: :string, required: false
      parameter name: 'filter[tradable_to]', in: :query, type: :string, required: false
      parameter name: 'filter[organic]', in: :query, type: :string, required: false
      parameter name: 'filter[gmo]', in: :query, type: :string, required: false
      parameter name: 'filter[heirloom]', in: :query, type: :string, required: false
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
                           description: { type: :string, 'x-nullable': true },
                           quantity: { type: :integer, 'x-nullable': true },
                           'plant-before': { type: :string, format: 'date', 'x-nullable': true },
                           'tradable-to': { type: :string, 'x-nullable': true },
                           'days-until-maturity-min': { type: :integer, 'x-nullable': true },
                           'days-until-maturity-max': { type: :integer, 'x-nullable': true },
                           organic: { type: :string, 'x-nullable': true },
                           gmo: { type: :string, 'x-nullable': true },
                           heirloom: { type: :string, 'x-nullable': true }
                         }
                       },
                       relationships: {
                         type: :object,
                         properties: {
                           owner: { '$ref' => '#/components/schemas/relationship' },
                           crop: { '$ref' => '#/components/schemas/relationship' }
                         }
                       }
                     }
                   }
                 }
               }

        let!(:seed) { FactoryBot.create(:seed) }
        run_test!
      end
    end

    post 'Creates a seed' do
      tags 'Seeds'
      consumes 'application/vnd.api+json'
      produces 'application/vnd.api+json'
      parameter name: :seed, in: :body, schema: {
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
                  }
                },
                required: ['crop']
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
        let(:seed) { { data: { type: 'seeds', attributes: { description: 'My API seed' }, relationships: { crop: { data: { type: 'crops', id: crop.id } } } } } }
        run_test!
      end

      response '401', 'unauthorized' do
        let(:crop) { create(:crop) }
        let(:seed) { { data: { type: 'seeds', attributes: { description: 'My API seed' }, relationships: { crop: { data: { type: 'crops', id: crop.id } } } } } }
        run_test!
      end
    end
  end

  path '/api/v1/seeds/{id}' do
    get 'Retrieves a seed' do
      tags 'Seeds'
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
                         description: { type: :string, 'x-nullable': true },
                         quantity: { type: :integer, 'x-nullable': true },
                         'plant-before': { type: :string, format: 'date', 'x-nullable': true },
                         'tradable-to': { type: :string, 'x-nullable': true },
                         'days-until-maturity-min': { type: :integer, 'x-nullable': true },
                         'days-until-maturity-max': { type: :integer, 'x-nullable': true },
                         organic: { type: :string, 'x-nullable': true },
                         gmo: { type: :string, 'x-nullable': true },
                         heirloom: { type: :string, 'x-nullable': true }
                       }
                     },
                     relationships: {
                       type: :object,
                       properties: {
                         owner: { '$ref' => '#/components/schemas/relationship' },
                         crop: { '$ref' => '#/components/schemas/relationship' }
                       }
                     }
                   }
                 }
               }
        let(:seed) { FactoryBot.create(:seed) }
        let(:id) { seed.id }
        run_test!
      end
    end

    patch 'Updates a seed' do
      tags 'Seeds'
      consumes 'application/vnd.api+json'
      produces 'application/vnd.api+json'
      parameter name: :id, in: :path, type: :string
      parameter name: :seed, in: :body, schema: {
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
        let(:seed_to_update) { create(:seed, owner: member) }
        let(:id) { seed_to_update.id }
        let(:seed) { { data: { type: 'seeds', id: id, attributes: { description: 'An updated seed' } } } }
        run_test!
      end

      response '401', 'unauthorized' do
        let(:seed_to_update) { create(:seed) }
        let(:id) { seed_to_update.id }
        let(:seed) { { data: { type: 'seeds', id: id, attributes: { description: 'An updated seed' } } } }
        run_test!
      end

      response '403', 'forbidden' do
        let(:member) { create(:member) }
        let(:token) do
          member.regenerate_api_token
          member.api_token.token
        end
        let(:Authorization) { "Token token=#{token}" }
        let(:other_member_seed) { create(:seed) }
        let(:id) { other_member_seed.id }
        let(:seed) { { data: { type: 'seeds', id: id, attributes: { description: 'An updated seed' } } } }
        run_test!
      end
    end

    delete 'Deletes a seed' do
      tags 'Seeds'
      parameter name: :id, in: :path, type: :string

      response '204', 'no content' do
        let(:member) { create(:member) }
        let(:token) do
          member.regenerate_api_token
          member.api_token.token
        end
        let(:Authorization) { "Token token=#{token}" }
        let(:seed_to_delete) { create(:seed, owner: member) }
        let(:id) { seed_to_delete.id }
        run_test!
      end

      response '401', 'unauthorized' do
        let(:seed_to_delete) { create(:seed) }
        let(:id) { seed_to_delete.id }
        run_test!
      end

      response '403', 'forbidden' do
        let(:member) { create(:member) }
        let(:token) do
          member.regenerate_api_token
          member.api_token.token
        end
        let(:Authorization) { "Token token=#{token}" }
        let(:other_member_seed) { create(:seed) }
        let(:id) { other_member_seed.id }
        run_test!
      end
    end
  end
end
