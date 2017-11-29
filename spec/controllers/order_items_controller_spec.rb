require 'rails_helper'

describe OrderItemsController do
  login_member(:admin_member)

  let(:member) { FactoryBot.create(:member) }
  let(:product) { FactoryBot.create(:product) }
  let(:order) { FactoryBot.create(:order, member: member) }
  let(:order_item) do
    FactoryBot.create(:order_item,
      order: order,
      product: product,
      price: product.min_price)
  end

  context 'signed in' do
    before { sign_in member }

    describe "POST create" do
      describe "redirects to order" do
        before do
          post :create, order_item: { order_id: order.id, product_id: product.id, price: product.min_price }
        end
        it { expect(response).to redirect_to(OrderItem.last.order) }
        it { expect(OrderItem.last.order).to be_an_instance_of Order }
      end

      describe 'creates an order for you' do
        it do
          expect do
            post :create, order_item: {
              product_id: product.id,
              price: product.min_price
            }
          end.to change(Order, :count).by(1)
        end
      end

      describe "with non-int price" do
        it "converts 3.33 to 333 cents" do
          order = FactoryBot.create(:order, member: member)
          product = FactoryBot.create(:product, min_price: 1)
          expect do
            post :create, order_item: { order_id: order.id, product_id: product.id, price: 3.33 }
          end.to change(OrderItem, :count).by(1)
          OrderItem.last.price.should eq 333
        end
      end
    end
  end
end
