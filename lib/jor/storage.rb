
module JOR
  class Storage
  
    NAMESPACE = "jor"
  
    SELECTORS = {
      :compare => ["$gt","$gte","$lt","$lte"],
      :sets => ["$in","$all"],
      :boolean => []
    }
    
    SELECTORS_ALL = SELECTORS.keys.inject([]) { |sel, element| sel | SELECTORS[element] } 
    
    def initialize(redis = nil)
      @redis = Redis.new() if @redis.nil?  
      @collections = {}
      reload_collections
    end

    def redis
      @redis
    end

    def collections
      @collections
    end
    
    def list_collections
      collections.keys
    end
    
    def create_collection(name)
      raise CollectionNotValid.new(name) if self.respond_to?(name)
      is_new = redis.sadd("#{Storage::NAMESPACE}/collections",name)
      raise CollectionAlreadyExists.new(name) if is_new==false or is_new==0
      reload_collections
    end
    
    def destroy_collection(name)
      raise CollectionDoesNotExist.new(name) unless @collections[name]
      coll_to_be_removed = @collections[name]
      redis.srem("#{Storage::NAMESPACE}/collections",name)
      reload_collections
      coll_to_be_removed.delete({})
      raise Exception.new("CRITICAL! Destroying the collection left some documents hanging") if coll_to_be_removed.count()!=0
    end
    
    def destroy_all()
      collections.keys.each do |col|
        destroy_collection(col)
      end
    end
    
    protected
    
    def reload_collections 
      coll = redis.smembers("#{Storage::NAMESPACE}/collections")
      tmp_collections = {}
      coll.each do |c|
        tmp_collections[c] = Collection.new(self,c)
      end
      @collections = tmp_collections
    end
    
    def method_missing(method)
      if !collections[method.to_s].nil?
        collections[method.to_s]
      else
        raise CollectionDoesNotExist.new(method.to_s)
      end
    end
       
  end
end
