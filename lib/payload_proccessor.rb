class PayloadProccessor
  @@instances = {}
  def initialize(model_data)
    @model_data = model_data
  end

  def proccess(payload)
    new_payload = payload.reject { |key, value| not @model_data['attributes'].include?(key) } #removes useless stuff
    new_payload.merge(@model_data['id'] => new_payload.delete('id')) #translates the id
  end

  def dependencies
    @model_data.fetch('check_for', [])
  end

  def self.new(*args, &block)
    old_instance = @@instances[args[0]['name']]
    return old_instance if old_instance

    obj = PayloadProccessor.allocate
    obj.send(:initialize, *args, &block)
    @@instances[args[0]['name']] = obj
    obj
  end
end