-- Notifications System for ManaKiraa Admin

-- 1. Create notifications table
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT NOT NULL, -- 'user', 'property', 'system'
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    link TEXT -- optional link to click
);

-- 2. Trigger for New User Registration
CREATE OR REPLACE FUNCTION public.notify_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.notifications (title, message, type, link)
    VALUES (
        'New User Registered',
        'A new user with email ' || NEW.email || ' has joined the platform.',
        'user',
        '/users'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_notified ON auth.users;
CREATE TRIGGER on_auth_user_notified
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.notify_new_user();

-- 3. Trigger for New Property Listing
CREATE OR REPLACE FUNCTION public.notify_new_property()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.notifications (title, message, type, link)
    VALUES (
        'New Property Listing',
        'A new property "' || NEW.name || '" has been added and needs verification.',
        'property',
        '/verifications'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_property_added_notified ON public.properties;
CREATE TRIGGER on_property_added_notified
    AFTER INSERT ON public.properties
    FOR EACH ROW EXECUTE FUNCTION public.notify_new_property();
