'use client';
import React from 'react';
import { useState } from 'react';
import dynamic from 'next/dynamic';
import Sidebar from '@/components/layout/Sidebar';
import Dashboard from '@/components/pages/Dashboard';
import UploadGroups from '@/components/pages/UploadGroups';
import UploadContacts from '@/components/pages/UploadContacts';
import ViewHierarchy from '@/components/pages/ViewHierarchy';
import SendMessages from '@/components/pages/SendMessages';

// Make sure the file exists at the specified path, or update the path if necessary
const ViewMessages = dynamic(() => import('../components/pages/ViewMessage'), { ssr: false });

export default function Home() {
  const [activeSection, setActiveSection] = useState('dashboard');

  const renderContent = () => {
    switch (activeSection) {
      case 'dashboard':
        return <Dashboard onNavigate={setActiveSection} />;
      case 'upload-groups':
        return <UploadGroups />;
      case 'upload-contacts':
        return <UploadContacts />;
      case 'view-hierarchy':
        return <ViewHierarchy />;
      case 'send-messages':
        return <SendMessages />;
      case 'view-messages':
        return <ViewMessages />;
      default:
        return <Dashboard onNavigate={setActiveSection} />;
    }
  };

  return (
    <div className="flex h-screen bg-gray-50">
      <Sidebar activeSection={activeSection} setActiveSection={setActiveSection} />
      <main className="flex-1 overflow-auto">
        <div className="p-6">
          {renderContent()}
        </div>
      </main>
    </div>
  );
}