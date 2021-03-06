class TemplatesController < ApplicationController
    #include ShopifyApp::AppProxyVerification
  skip_before_filter :verify_authenticity_token
  include ShopifyApp::AppProxyVerification
  include AppProxyAuth
  
  def index
  end
  
  def create
      connect_to_shopify
      order     = ShopifyAPI::Order.find(template_params[:order_id])
      variant_ids   = []
      variants      = []
      
      order.line_items.each do |line_item|
          variant_ids.push line_item.variant_id
      end
      
      variant_ids.each do |variant_id|
          variant_data = ShopifyAPI::Variant.find(variant_id)
          sku = variant_data.sku
          if sku.include? "24H"
              variant_hash = {
                                "product_id" => variant_data.product_id,
                                "variant_id" => variant_id, 
                                "title"      => ShopifyAPI::Product.find(variant_data.product_id).title,
                                "sku"        => variant_data.sku,
                                "price"      => variant_data.price
                              }
              variants.push variant_hash.to_json
          else
              search_sku = sku
              sku.split('_').each do |part|
                  if part[part.length-1] == "H" and part != 'CLIPPING-PATH'
                    search_sku.gsub!( part, '24H' )
                  end
                  
              end
              
              ShopifyAPI::Product.all.each do |product|
                  product.variants.each do |variant|
                    if variant.sku == search_sku
                        variant_hash = { 
                                "product_id" => product.id,
                                "variant_id" => variant.id, 
                                "title"      => product.title,
                                "sku"        => variant.sku,
                                "price"      => variant.price
                              }
                        variants.push variant_hash.to_json
                    end
                  end
              end
          end
      end
      
      variants = variants.uniq
      template_data = template_params
      
      template_data[:product_variants] = variants
   
      @template = Template.new(template_data)
      
      if @template.save
          @result = 'Template was successfully created!'
      else
          @result = @template.errors.full_messages.join(',')
      end
      
  end
  
  def delete
      
      template          = Template.find params[:id]
      template.deleted  = true  
      @id               = 'template-' + params[:id]
      
      if template.save
          @result = 'Template was successfully deleted!'
      else
          @result = template.errors.full_messages.join(',')
      end
      
  end
  
  def update
      
      @template = Template.find params[:id]
      @rename   ||= params[:template][:rename]
      
      if @template.update_attributes(template_params)
          @result   = 'Template was successfully updated!'
      else
          @result = @template.errors.full_messages.join(',')
      end
  end
  
  def save_image
    
    template = Template.find params[:id]
    
    if template.sample_image_url
      unless template.sample_image_url.empty?
        sample_image_url  = url_decode template.sample_image_url
        key               = sample_image_url.split('amazonaws.com/').last.gsub '+', ' '
        S3_BUCKET.object(key).delete
      end
    end
    
    template.sample_image_url = params[:image_url]
    
    respond_to :html, :json
    
    if template.save
       render json:{
                    status: 'success',
                    result: 'Success to save template image!'
                }
    else
      render json:{
                    status: 'error',
                    message: "Error! #{template.errors.full_messages.join(',')}"
                }
    end
    
  end
  
  def delete_image
    
    template          = Template.find params[:id]
    sample_image_url  = url_decode template.sample_image_url
    key               = sample_image_url.split('amazonaws.com/').last.gsub '+', ' '
    
    respond_to :html, :json
    if S3_BUCKET.object(key).delete
      template.sample_image_url = ''
      if template.save
        render json:{
          status: 'success',
          result: 'Success to delete sample image.'
        }
      else
        render json:{
          status: 'error',
          message: "Error! #{template.errors.full_messages.join(',')}"
        }
      end
    else
      render json:{
        status: 'error',
        message: 'Amazon API error!'
      }
    end
      
  end
  
  # def show
  #   @template = Template.find params[:id]
  #   set_s3_direct_post
  #   render layout: 'guest', content_type: 'application/liquid'
  # end
      
  private
    def template_params
        params.require(:template).permit( :order_id,
                                          :customer_id,
                                          :template_name,
                                          :message,
                                          :return_file_format,
                                          :set_margin,
                                          :resize_image,
                                          :image_width,
                                          :image_height,
                                          :message_for_production,
                                          :additional_comment,
                                          :product_variants,
                                          :quotation_id
                                          )
    end
    
    def url_decode(s)
       s.gsub(/((?:%[0-9a-fA-F]{2})+)/n) do
         [$1.delete('%')].pack('H*')
       end
    end

end
