class PurchasesController < ApplicationController
  require 'japan_postal_code'

  def new
    @order = Order.new
    @souko_zaikos = []
  end

  def create
    @order = Order.new(order_params)
    @order.order_number = generate_order_number
    @order.delivery_zipcode = params[:zipcode]
    @order.total_amount = params[:grand_total_after_tax]
    @order.tax = params[:tax]

    if @order.save!
      # Build order items from params
      order_items_params.each do |item|
        @order.order_items.create(
            sku_code: item[:item_name],
            quantity: item[:quantity].to_i,
            price: item[:price].to_i,
            total_amount: item[:total_price].to_i
          )
      end

      if check_stock_availability(@order.order_items)
        if process_order(@order)
          redirect_to new_purchase_path, notice: 'Order successfully created.'
        else
          @order.destroy # Rollback if process_order fails
          redirect_to new_purchase_path, alert: 'Failed to process the order.'
        end
      else
        @order.destroy # Rollback if stock check fails
        redirect_to new_purchase_path, alert: 'Insufficient stock for one or more items.'
      end
    else
      render :new
    end
  end

  def fetch_zipcode_info
    postal_code = params[:zipcode]

    # Load postal data (you can preload this for performance)
    postal_loader = JapanPostalCode.new.load('NATIONAL')
    postal_areas = postal_loader.lookup_by_code(postal_code)

    if postal_areas.any?
      postal_info = postal_areas.first # Take the first match
      render json: {
        postal_code: postal_info[0],
        state: postal_info[1],
        city: postal_info[2],
        area: postal_info[3]
      }
    else
      render json: { error: 'Invalid ZIP code' }, status: :unprocessable_entity
    end
  end

  def items_for_ew_flag
    ew_flag = params[:ew_flag]
    warehouse_code = ew_flag == "E" ? "EAST" : "WEST" # Adjust this logic as needed
    items = SoukoZaiko.where(warehouse_code: warehouse_code, stock_type: "01")

    render json: items.map { |item| { sku_code: item.sku_code, price: item.stock_type, warehouse_code: item.warehouse_code } }
  end

  private

  def order_params
    params.require(:order).permit(
      :delivery_zipcode, :delivery_state, :delivery_city, :delivery_area, :delivery_address,
      order_items_attributes: [:warehouse_code, :item_name, :quantity, :price, :total_price]
    )
  end

  def order_items_params
    params[:items].map do |item|
      item.permit(:warehouse_code, :item_name, :quantity, :price, :total_price)
    end
  end

  def generate_order_number
    date_str = Time.current.strftime("%Y%m%d")
    last_order = Order.where("order_number LIKE ?", "#{date_str}%").order("order_number DESC").first
    last_number = last_order ? last_order.order_number[-5..-1].to_i : 0
    new_number = last_number + 1
    format("#{date_str}%05d", new_number)
  end

  def process_order(order)
    ew_flag = PrefectureCode.find_by(name: order.delivery_state)&.ew_flag
    return false unless ew_flag

    order.order_items.each do |item|
      warehouse_code = ew_flag == "E" ? "EAST" : "WEST"
      souko = SoukoZaiko.find_by(sku_code: item.sku_code, warehouse_code: warehouse_code)

      if souko && souko.stock >= item.quantity
        souko.stock -= item.quantity
        souko.save!

        # Create new stock entry for sold items
        SoukoZaiko.create!(
          sku_code: item.sku_code,
          stock_type: '02',
          stock: item.quantity,
          warehouse_code: warehouse_code
        )
      else
        return false
      end
    end

    true
  end

  def check_stock_availability(order_items)
    order_items.all? do |item|
      warehouse_code = params[:items][0][:warehouse_code]
      souko = SoukoZaiko.find_by(sku_code: item.sku_code, warehouse_code: warehouse_code)
      souko && souko.stock >= item.quantity
    end
  end
end
