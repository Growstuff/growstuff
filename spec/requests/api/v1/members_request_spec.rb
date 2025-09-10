# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Members API', type: :request do
  path '/api/v1/members' do
    get 'Lists members' do
      tags 'Members'
      produces 'application/vnd.api+json'
      parameter name: 'filter[login_name]', in: :query, type: :string, required: false
      parameter name: 'filter[slug]', in: :query, type: :string, required: false

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
                           'login-name': { type: :string },
                           slug: { type: :string }
                         }
                       },
                       relationships: {
                         type: :object,
                         properties: {
                           gardens: { '$ref' => '#/components/schemas/relationship' },
                           harvests: { '$ref' => '#/components/schemas/relationship' },
                           photos: { '$ref' => '#/components/schemas/relationship' },
                           plantings: { '$ref' => '#/components/schemas/relationship' },
                           seeds: { '$ref' => '#/components/schemas/relationship' }
                         }
                       }
                     }
                   }
                 }
               }

        let!(:member) { FactoryBot.create(:member) }
        run_test!
      end
    end
  end

  path '/api/v1/members/{id}' do
    get 'Retrieves a member' do
      tags 'Members'
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
                         'login-name': { type: :string },
                         slug: { type: :string }
                       }
                     },
                     relationships: {
                       type: :object,
                       properties: {
                         gardens: { '$ref' => '#/components/schemas/relationship' },
                         harvests: { '$ref' => '#/components/schemas/relationship' },
                         photos: { '$ref' => '#/components/schemas/relationship' },
                         plantings: { '$ref' => '#/components/schemas/relationship' },
                         seeds: { '$ref' => '#/components/schemas/relationship' }
                       }
                     }
                   }
                 }
               }
        let(:member) { FactoryBot.create(:member) }
        let(:id) { member.id }
        run_test!
      end
    end
  end
end
