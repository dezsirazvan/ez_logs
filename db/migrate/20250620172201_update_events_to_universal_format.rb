class UpdateEventsToUniversalFormat < ActiveRecord::Migration[8.0]
  def change
    # Add new UniversalEvent fields
    add_column :events, :event_id, :string unless column_exists?(:events, :event_id)
    add_column :events, :correlation_id, :string unless column_exists?(:events, :correlation_id)
    add_column :events, :actor, :json unless column_exists?(:events, :actor)
    add_column :events, :subject, :json unless column_exists?(:events, :subject)
    add_column :events, :correlation, :json unless column_exists?(:events, :correlation)
    add_column :events, :correlation_context, :json unless column_exists?(:events, :correlation_context)
    add_column :events, :payload, :json unless column_exists?(:events, :payload)
    add_column :events, :platform, :json unless column_exists?(:events, :platform)
    add_column :events, :validation_errors, :json, default: [] unless column_exists?(:events, :validation_errors)
    add_index :events, :event_id, unique: true unless index_exists?(:events, :event_id)
    add_index :events, :correlation_id unless index_exists?(:events, :correlation_id)
    add_index :events, :timestamp unless index_exists?(:events, :timestamp)

    # Remove severity column if it exists
    remove_column :events, :severity, :string if column_exists?(:events, :severity)

    # Migrate existing data to new format
    reversible do |dir|
      dir.up do
        # Migrate existing actor_type/actor_id to actor JSON
        execute <<-SQL
          UPDATE events 
          SET actor = CASE 
            WHEN actor_type IS NOT NULL AND actor_id IS NOT NULL 
            THEN json_build_object('type', actor_type, 'id', actor_id)
            ELSE NULL
          END
        SQL
        
        # Migrate existing subject_type/subject_id to subject JSON
        execute <<-SQL
          UPDATE events 
          SET subject = CASE 
            WHEN subject_type IS NOT NULL AND subject_id IS NOT NULL 
            THEN json_build_object('type', subject_type, 'id', subject_id)
            ELSE NULL
          END
        SQL
        
        # Generate event_id for existing records if not present
        execute <<-SQL
          UPDATE events 
          SET event_id = 'evt_' || substr(md5(random()::text || clock_timestamp()::text), 1, 16)
          WHERE event_id IS NULL
        SQL
        
        # Generate correlation_id for existing records if not present
        execute <<-SQL
          UPDATE events 
          SET correlation_id = 'flow_' || substr(md5(random()::text || clock_timestamp()::text), 1, 16)
          WHERE correlation_id IS NULL
        SQL
        
        # Build basic correlation context
        execute <<-SQL
          UPDATE events 
          SET correlation = json_build_object('correlation_id', correlation_id)
        SQL
        
        # Build basic platform context
        execute <<-SQL
          UPDATE events 
          SET platform = json_build_object(
            'service', 'ez-logs',
            'environment', 'production',
            'agent_version', '1.0.0'
          )
        SQL
      end
      
      dir.down do
        # Revert actor JSON back to separate fields
        execute <<-SQL
          UPDATE events 
          SET actor_type = actor->>'type',
              actor_id = actor->>'id'
        SQL
        
        # Revert subject JSON back to separate fields
        execute <<-SQL
          UPDATE events 
          SET subject_type = subject->>'type',
              subject_id = subject->>'id'
        SQL
      end
    end
    
    # Remove old columns after migration
    remove_column :events, :actor_type, :string if column_exists?(:events, :actor_type)
    remove_column :events, :actor_id, :string if column_exists?(:events, :actor_id)
    remove_column :events, :subject_type, :string if column_exists?(:events, :subject_type)
    remove_column :events, :subject_id, :string if column_exists?(:events, :subject_id)
  end
end
