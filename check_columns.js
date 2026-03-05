const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://ykvogmlldhqapvbpjzto.supabase.co';
const supabaseAnonKey = 'sb_publishable_UtqGxDX6f1qM4aYUMMFKRg__MQoil7V';

const supabase = createClient(supabaseUrl, supabaseAnonKey);

async function checkColumns() {
    const { data, error } = await supabase.from('properties').select().limit(1);
    if (error) {
        console.error('Error:', error);
    } else {
        console.log('Sample Data:', data[0]);
        console.log('Columns:', Object.keys(data[0] || {}));
    }
}

checkColumns();
