# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Photos API', type: :request do
  path '/api/v1/photos' do
    get 'Lists photos' do
      tags 'Photos'
      produces 'application/vnd.api+json'

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
                           'thumbnail-url': { type: :string, format: :uri },
                           'fullsize-url': { type: :string, format: :uri },
                           'license-name': { type: :string },
                           'link-url': { type: :string, format: :uri },
                           title: { type: :string }
                         }
                       },
                       relationships: {
                         type: :object,
                         properties: {
                           owner: { '$ref' => '#/components/schemas/relationship' },
                           plantings: { '$ref' => '#/components/schemas/relationship' },
                           gardens: { '$ref' => '#/components/schemas/relationship' },
                           harvests: { '$ref' => '#/components/schemas/relationship' }
                         }
                       }
                     }
                   }
                 }
               }

        let!(:photo) { FactoryBot.create(:photo) }
        run_test!
      end
    end
  end

  path '/api/v1/photos/{id}' do
    get 'Retrieves a photo' do
      tags 'Photos'
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
                         'thumbnail-url': { type: :string, format: :uri },
                         'fullsize-url': { type: :string, format: :uri },
                         'license-name': { type: :string },
                         'link-url': { type: :string, format: :uri },
                         title: { type: :string }
                       }
                     },
                     relationships: {
                       type: :object,
                       properties: {
                         owner: { '$ref' => '#/components/schemas/relationship' },
                         plantings: { '$ref' => '#/components/schemas/relationship' },
                         gardens: { '$ref' => '#/components/schemas/relationship' },
                         harvests: { '$ref' => '#/components/schemas/relationship' }
                       }
                     }
                   }
                 }
               }
        let(:photo) { FactoryBot.create(:photo) }
        let(:id) { photo.id }
        run_test!
      end
    end
  end
end
