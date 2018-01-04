require 'rails_helper'

describe ShopController do
  let!(:product1) { FactoryBot.create(:product, name: 'aaa') }
  let!(:product2) { FactoryBot.create(:product, name: 'zzz') }

  describe "GET index" do
    describe 'not logged in' do
      before { get :index, params: {} }

      describe "assigns all products as @products ordered by name" do
        it { expect(assigns(:products)).to eq([product1, product2]) }
      end

      describe "assigns a new @order_item to build forms" do
        it { expect(assigns(:order_item)).to be_an_instance_of OrderItem }
      end

      describe "assigns @order as nil if the user doesn't have one" do
        it { expect(assigns(:order)).to be_nil }
      end
    end
    describe 'logged in' do
      describe "assigns @order as current_order if there is one" do
        let(:member) { FactoryBot.create(:member) }
        let!(:order) { FactoryBot.create(:order, member: member) }
        before do
          sign_in member
          get :index, params: {}
        end
        it { expect(assigns(:order)).to eq order }
      end
    end
  end
end
