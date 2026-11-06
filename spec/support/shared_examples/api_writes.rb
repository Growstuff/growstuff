# frozen_string_literal: true

# What /api/v1 does when members create, change and delete a kind of record.
#
# The including group says which kind, with:
#   create_params - what goes in the request's `data` besides its type: `attributes` and `relationships`
#   own_record    - a record belonging to `member`
#   other_record  - a record belonging to someone else
#   changes       - attributes to change on own_record, by their model names
RSpec.shared_examples 'a resource members can write' do |type|
  include_context 'with an API member'

  let(:resource_type) { type }
  let(:model) { type.classify.constantize }
  let(:path) { "/api/v1/#{type}" }

  def body(data)
    { data: { type: resource_type }.merge(data) }.to_json
  end

  describe 'creating' do
    context 'without a token' do
      it 'is unauthorized' do
        post path, params: body(create_params), headers: write_headers
        expect(response).to have_http_status(:unauthorized)
      end

      it 'creates nothing' do
        expect { post path, params: body(create_params), headers: write_headers }.not_to change(model, :count)
      end
    end

    context 'with a token' do
      before { token }

      it 'is created' do
        post path, params: body(create_params), headers: auth_headers
        expect(response).to have_http_status(:created)
      end

      it 'belongs to the token holder' do
        expect { post path, params: body(create_params), headers: auth_headers }.to change { model.where(owner: member).count }.by(1)
      end
    end
  end

  describe 'updating' do
    let(:update_body) { body(id: own_record.id.to_s, attributes: changes) }

    it 'is unauthorized without a token' do
      patch "#{path}/#{own_record.id}", params: update_body, headers: write_headers
      expect(response).to have_http_status(:unauthorized)
    end

    context 'with your own' do
      before { patch "#{path}/#{own_record.id}", params: update_body, headers: auth_headers }

      it { expect(response).to have_http_status(:ok) }

      it 'saves the changes' do
        expect(own_record.reload.slice(*changes.keys).symbolize_keys).to eq(changes)
      end
    end

    context 'with someone else\'s' do
      before { patch "#{path}/#{other_record.id}", params: body(id: other_record.id.to_s, attributes: changes), headers: auth_headers }

      it { expect(response).to have_http_status(:forbidden) }

      it 'leaves it alone' do
        expect(other_record.reload.slice(*changes.keys).symbolize_keys).not_to eq(changes)
      end
    end
  end

  describe 'deleting' do
    it 'is unauthorized without a token' do
      delete "#{path}/#{own_record.id}", headers: write_headers
      expect(response).to have_http_status(:unauthorized)
    end

    context 'with your own' do
      before { delete "#{path}/#{own_record.id}", headers: auth_headers }

      it { expect(response).to have_http_status(:no_content) }

      it 'removes it' do
        expect(model.find_by(id: own_record.id)).to be_nil
      end
    end

    context 'with someone else\'s' do
      before { delete "#{path}/#{other_record.id}", headers: auth_headers }

      it { expect(response).to have_http_status(:forbidden) }

      it 'keeps it' do
        expect(model.find_by(id: other_record.id)).to be_present
      end
    end
  end
end
