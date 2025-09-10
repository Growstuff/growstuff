# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Gardens API', type: :request do
  path '/api/v1/gardens' do
    get 'Lists gardens' do
      tags 'Gardens'
      produces 'application/vnd.api+json'
      parameter name: 'filter[active]', in: :query, type: :string, required: false
      parameter name: 'filter[garden_type]', in: :query, type: :string, required: false
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
                           name: { type: :string }
                         }
                       },
                       relationships: {
                         type: :object,
                         properties: {
                           owner: { '$ref' => '#/components/schemas/relationship' },
                           plantings: { '$ref' => '#/components/schemas/relationship' },
                           photos: { '$ref' => '#/components/schemas/relationship' }
                         }
                       }
                     }
                   }
                 }
               }

        let!(:garden) { FactoryBot.create(:garden) }
        run_test!
      end
    end

    post 'Creates a garden' do
      tags 'Gardens'
      consumes 'application/vnd.api+json'
      produces 'application/vnd.api+json'
      parameter name: :garden, in: :body, schema: {
        type: :object,
        properties: {
          data: {
            type: :object,
            properties: {
              type: { type: :string },
              attributes: {
                type: :object,
                properties: {
                  name: { type: :string }
                },
                required: ['name']
              }
            },
            required: ['type', 'attributes']
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
        let(:garden) { { data: { type: 'gardens', attributes: { name: 'My API Garden' } } } }
        run_test!
      end

      response '401', 'unauthorized' do
        let(:garden) { { data: { type: 'gardens', attributes: { name: 'My API Garden' } } } }
        run_test!
      end
    end
  end

  path '/api/v1/gardens/{id}' do
    get 'Retrieves a garden' do
      tags 'Gardens'
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
                         name: { type: :string }
                       }
                     },
                     relationships: {
                       type: :object,
                       properties: {
                         owner: { '$ref' => '#/components/schemas/relationship' },
                         plantings: { '$ref' => '#/components/schemas/relationship' },
                         photos: { '$ref' => '#/components/schemas/relationship' }
                       }
                     }
                   }
                 }
               }
        let(:garden) { FactoryBot.create(:garden) }
        let(:id) { garden.id }
        run_test!
      end
    end

    patch 'Updates a garden' do
      tags 'Gardens'
      consumes 'application/vnd.api+json'
      produces 'application/vnd.api+json'
      parameter name: :id, in: :path, type: :string
      parameter name: :garden, in: :body, schema: {
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
                  name: { type: :string }
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
        let(:garden_to_update) { create(:garden, owner: member) }
        let(:id) { garden_to_update.id }
        let(:garden) { { data: { type: 'gardens', id: id, attributes: { name: 'An updated garden' } } } }
        run_test!
      end

      response '401', 'unauthorized' do
        let(:garden_to_update) { create(:garden) }
        let(:id) { garden_to_update.id }
        let(:garden) { { data: { type: 'gardens', id: id, attributes: { name: 'An updated garden' } } } }
        run_test!
      end

      response '403', 'forbidden' do
        let(:member) { create(:member) }
        let(:token) do
          member.regenerate_api_token
          member.api_token.token
        end
        let(:Authorization) { "Token token=#{token}" }
        let(:other_member_garden) { create(:garden) }
        let(:id) { other_member_garden.id }
        let(:garden) { { data: { type: 'gardens', id: id, attributes: { name: 'An updated garden' } } } }
        run_test!
      end
    end

    delete 'Deletes a garden' do
      tags 'Gardens'
      parameter name: :id, in: :path, type: :string

      response '204', 'no content' do
        let(:member) { create(:member) }
        let(:token) do
          member.regenerate_api_token
          member.api_token.token
        end
        let(:Authorization) { "Token token=#{token}" }
        let(:garden_to_delete) { create(:garden, owner: member) }
        let(:id) { garden_to_delete.id }
        run_test!
      end

      response '401', 'unauthorized' do
        let(:garden_to_delete) { create(:garden) }
        let(:id) { garden_to_delete.id }
        run_test!
      end

      response '403', 'forbidden' do
        let(:member) { create(:member) }
        let(:token) do
          member.regenerate_api_token
          member.api_token.token
        end
        let(:Authorization) { "Token token=#{token}" }
        let(:other_member_garden) { create(:garden) }
        let(:id) { other_member_garden.id }
        run_test!
      end
    end
  end
end
