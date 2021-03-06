require 'opinio/opinio_model/validations'

module Opinio
  module OpinioModel

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
    
      # Adds the Opinio functionallity to the model
      # You can pass a hash of options to customize the Opinio model
      def opinio(*args)
        return if self.included_modules.include?(Opinio::OpinioModel::Validations)
        options = args.extract_options!

        if Opinio.use_title
          attr_accessible :title 
        end
        attr_accessible :body

        belongs_to :commentable, :polymorphic => true, :counter_cache => options.fetch(:counter_cache, false) 
        belongs_to :owner, :class_name => options.fetch(:owner_class_name, Opinio.owner_class_name)

        scope :owned_by, lambda {|owner| where('owner_id = ?', owner.id) }

        send :include, Opinio::OpinioModel::Validations

        if Opinio.accept_replies
          send :include, RepliesSupport
        end

        if Opinio.strip_html_tags_on_save
          send :include, Sanitizing
        end

      end
    end

    module Sanitizing
      def self.included(base)
        base.class_eval do
          send :include, ActionView::Helpers::SanitizeHelper
          before_save :strip_html_tags
        end
      end

      private

      def strip_html_tags
        self.body = strip_tags(self.body)
      end
    end

    module RepliesSupport
      def self.included(base)
        base.class_eval do
          opinio_subjectum :order => 'created_at ASC'
        end
      end

    end
  end
end
